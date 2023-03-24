import 'dart:io';

import 'package:path/path.dart' as path;

import 'database/database_service.dart';
import 'model/code_file.dart';
import 'utils/log.dart';
import 'utils/utils.dart';

class CachedBuildRunner {
  final DatabaseService _databaseService;

  CachedBuildRunner(this._databaseService);

  /// this method runs an efficient version of `build_runner build`
  Future<void> build() async {
    Utils.logHeader('Determining Files that needs code generation');

    final libFiles = _fetchFilePathsFromLib();
    final testFiles = await _fetchFilePathsFromTest();
    final files = List<CodeFile>.from(libFiles)..addAll(testFiles);

    final List<CodeFile> goodFiles = [];
    final List<CodeFile> badFiles = [];

    final bulkMapping = await _databaseService.isMappingAvailableForBulk(files.map((f) => f.digest));

    /// segregate good and bad files
    /// good files -> files for whom the generated codes are available
    /// bad files -> files for whom no generated codes are available in the cache
    for (final file in files) {
      final isGeneratedCodeAvailable = bulkMapping[file.digest] == true;

      /// mock generated files are always considered badFiles,
      /// as they depends on various services, and to keep track of changes can become complicated
      if (isGeneratedCodeAvailable) {
        goodFiles.add(file);
      } else {
        badFiles.add(file);
      }
    }

    Logger.v('No. of cached files: ${goodFiles.length}');
    Logger.v('No. of non-cached files: ${badFiles.length}');

    /// let's handle bad files - by generating the .g.dart / .mocks.dart files for them
    _generateCodesFor(badFiles);

    /// let's handle the good files - by copying the cached generated files to appropriate path
    /// we pass in the bad files as well, in case the good files could not be copied,
    /// they become bad files - though this should NOT happen, still a safe mechanism to avoid complete error
    await _copyGeneratedCodesFor(goodFiles, badFiles);

    /// at last, let's cache the bad files - they may be required next time
    await _cacheGeneratedCodesFor(badFiles);

    /// let's flush Hive, to make sure everything is committed to disk
    await _databaseService.flush();

    /// We are done, probably?
  }

  Future<void> _copyGeneratedCodesFor(List<CodeFile> files, List<CodeFile> badFiles) async {
    Utils.logHeader('Copying cached codes to project directory');

    for (final file in files) {
      final cachedGeneratedCodePath = await _databaseService.getCachedFilePath(file.digest);
      Logger.v('Copying cache to: ${Utils.getFileName(_getGeneratedFilePathFrom(file))}');
      File(cachedGeneratedCodePath).copySync(_getGeneratedFilePathFrom(file));

      /// check if the file was copied successfully
      if (!File(_getGeneratedFilePathFrom(file)).existsSync()) {
        Logger.e('ERROR: _copyGeneratedCodesFor: failed to copy the cached file $file');
        badFiles.add(file);
      }
    }
  }

  /// converts "./cta_model.dart" to "./cta_model.g.dart"
  /// OR
  /// converts "./otp_screen_test.dart" to "./otp_screen_test.mocks.dart";
  String _getGeneratedFilePathFrom(CodeFile file) {
    final path = file.path;
    final lastDotDart = path.lastIndexOf('.dart');
    final extension = file.isTestFile ? '.mocks.dart' : '.g.dart';

    if (lastDotDart >= 0) {
      return '${path.substring(0, lastDotDart)}$extension';
    }

    return path;
  }

  String _getBuildFilterList(List<CodeFile> files) {
    final paths = files.map<String>((codeFile) => _getGeneratedFilePathFrom(codeFile)).toList();
    return paths.join(',');
  }

  /// this method runs build_runner build method with --build-filter
  /// to only generate the required codes, thus avoiding unnecessary builds
  void _generateCodesFor(List<CodeFile> files) {
    if (files.isEmpty) return;
    Utils.logHeader('Generating Codes for non-cached files, found ${files.length} files');

    if (files.isEmpty) return;

    /// following command needs to be executed
    /// flutter pub run build_runner build --build-filter="..." -d
    /// where ... contains the list of files that needs generation

    Logger.v('Running build_runner build...');
    final process = Process.runSync(
      'flutter',
      [
        'pub',
        'run',
        'build_runner',
        'build',
        '--build-filter',
        _getBuildFilterList(files),
        '--delete-conflicting-outputs'
      ],
      workingDirectory: Utils.projectDirectory,
    );

    if (process.stderr.toString().isNotEmpty) {
      throw Exception('_generateCodesFor :: failed to run build_runner build :: ${process.stderr}');
    }

    Logger.v(process.stdout);
  }

  final _generateMocksFormattingRegex = RegExp(r'(.*?):@GenerateMocks\(\[(.*?)\]\)', dotAll: true);

  List<List<String>> _formatOutput(String input) {
    final matches = _generateMocksFormattingRegex.allMatches(input);
    final List<List<String>> output = [];

    for (final match in matches) {
      if (match.groupCount >= 2) {
        final filePath = match.group(1) ?? '';
        final dependencies = match.group(2) ?? '';

        output.add([filePath.trim(), ...dependencies.split(',').map((s) => s.trim())]);
      }
    }

    return output;
  }

  Future<List<CodeFile>> _fetchFilePathsFromTest() async {
    if (!Utils.generateTestMocks) return const [];

    final List<CodeFile> codeFiles = [];

    final pcregrepProcess = Process.runSync(
      'pcregrep',
      ['-r', '-M', "(?s)@GenerateMocks(.*?)]", path.join(Utils.projectDirectory, 'test')],
      runInShell: true,
    );

    if (pcregrepProcess.stderr.toString().isNotEmpty) {
      throw Exception('_fetchFilePathsFromTest :: failed to run pcregrepProcess :: ${pcregrepProcess.stderr}');
    }

    final grepOutput = pcregrepProcess.stdout.toString();

    for (final files in _formatOutput(grepOutput)) {
      codeFiles.add(
        CodeFile(
          path: files[0].trim(),
          digest: Utils.calculateTestFileDigestFor(files),
          isTestFile: true,
        ),
      );
    }

    Logger.v('Found ${codeFiles.length} files in "test/" that needs code generation');

    return codeFiles;
  }

  /// this method returns all the files that needs code generations
  List<CodeFile> _fetchFilePathsFromLib() {
    /// Files in "lib/" that needs code generation
    final libRegExp = RegExp(r"part '.+\.g\.dart';");

    final libProcess = Process.runSync(
      'grep',
      [
        '-r',
        '-l',
        '-E',
        libRegExp.pattern,
        '--include=*.dart',
        '--exclude=*.g.dart',
        path.join(Utils.projectDirectory, 'lib'),
      ],
      runInShell: true,
    );

    final libPathList = libProcess.stdout.toString().split('\n').where(
          (line) => line.isNotEmpty,
        );

    Logger.v('Found ${libPathList.length} files in "lib/" that needs code generation');

    return libPathList
        .map<CodeFile>(
          (path) => CodeFile(
            path: path.trim(),
            digest: Utils.calculateDigestFor(path),
          ),
        )
        .toList();
  }

  /// copies the generated files to cache directory, and make an entry in database
  Future<void> _cacheGeneratedCodesFor(List<CodeFile> files) async {
    if (files.isEmpty) return;

    Utils.logHeader('Caching new generated codes, caching ${files.length} files');

    for (final file in files) {
      Logger.v('Caching generated code for: ${Utils.getFileName(file.path)}');
      final cachedFilePath = path.join(Utils.appCacheDirectory, file.digest);
      File(_getGeneratedFilePathFrom(file)).copySync(cachedFilePath);

      final cacheEntry = <String, String>{};

      /// if file has been successfully copied, let's make an entry to the db
      if (File(cachedFilePath).existsSync()) {
        cacheEntry[file.digest] = cachedFilePath;
      } else {
        Logger.e('ERROR: _cacheGeneratedCodesFor: failed to copy generated file $file');
      }

      /// create a bulk entry
      await _databaseService.createEntryForBulk(cacheEntry);
    }
  }
}
