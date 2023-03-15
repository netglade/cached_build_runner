import 'dart:io';

import 'package:path/path.dart' as path;

import 'database/database_service.dart';
import 'model/code_file.dart';
import 'utils/log.dart';
import 'utils/utils.dart';

class BuildCache {
  final DatabaseService _databaseService;

  BuildCache(this._databaseService);

  /// this method runs an efficient version of `build_runner build`
  Future<void> build() async {
    Utils.logHeader('DETERMINING FILES THAT NEEDS GENERATION');

    final libFiles = _fetchFilePathsFromLib();
    final testFiles = await _fetchFilePathsFromTest();
    final files = List.from(libFiles)..addAll(testFiles);

    final List<CodeFile> goodFiles = [];
    final List<CodeFile> badFiles = [];

    /// segregate good and bad files
    /// good files -> files for whom the generated codes are available
    /// bad files -> files for whom no generated codes are available in the cache
    for (final file in files) {
      final isGeneratedCodeAvailable = _databaseService.isMappingAvailable(file.digest);

      /// mock generated files are always considered badFiles,
      /// as they depends on various services, and to keep track of changes can become complicated
      if (isGeneratedCodeAvailable) {
        goodFiles.add(file);
      } else {
        badFiles.add(file);
      }
    }

    Logger.log('No. of good files: ${goodFiles.length}');
    Logger.log('No. of bad files: ${badFiles.length}');

    /// let's handle bad files - by generating the .g.dart / .mocks.dart files for them
    _generateCodesFor(badFiles);

    /// let's handle the good files - by copying the cached generated files to appropriate path
    /// we pass in the bad files as well, in case the good files could not be copied,
    /// they become bad files - though this should NOT happen, still a safe mechanism to avoid complete error
    _copyGeneratedCodesFor(goodFiles, badFiles);

    /// at last, let's cache the bad files - they may be required next time
    _cacheGeneratedCodesFor(badFiles);

    /// let's flush Hive, to make sure everything is committed to disk
    await _databaseService.flush();

    /// We are done, probably?
  }

  void _copyGeneratedCodesFor(List<CodeFile> files, List<CodeFile> badFiles) {
    Utils.logHeader('COPYING CACHED GENERATED CODES');

    for (final file in files) {
      final cachedGeneratedCodePath = _databaseService.getCachedFilePath(file.digest);
      Logger.log('Copying cache to: ${Utils.getFileName(_getGeneratedFilePathFrom(file))}');

      final process = Process.runSync(
        'cp',
        [
          cachedGeneratedCodePath,
          _getGeneratedFilePathFrom(file),
        ],
      );

      if (process.stderr.toString().isNotEmpty) {
        Logger.log('ERROR: _copyGeneratedCodesFor: ${process.stderr}', fatal: true);
      }

      /// check if the file was copied successfully
      if (!File(_getGeneratedFilePathFrom(file)).existsSync()) {
        Logger.log('ERROR: _copyGeneratedCodesFor: failed to copy the cached file $file', fatal: true);
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
    Utils.logHeader(
      'GENERATING CODES FOR BAD FILES (${files.length})',
    );

    if (files.isEmpty) return;

    /// following command needs to be executed
    /// flutter pub run build_runner build --build-filter="..." -d
    /// where ... contains the list of files that needs generation

    Logger.log('Running build_runner build...');
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

    Logger.log(process.stdout);
  }

  final _generateMocksFormattingRegex = RegExp(r'(.*):@GenerateMocks\(\[(.*)\]\)');

  String _formatOutput(String input) {
    final match = _generateMocksFormattingRegex.firstMatch(input);
    final fileName = match?.group(1);
    final items = match?.group(2);
    final formattedItems = items?.replaceAll(',', '');

    return '$fileName $formattedItems';
  }

  Future<List<CodeFile>> _fetchFilePathsFromTest() async {
    if (!Utils.generateTestMocks) return const [];

    final List<CodeFile> codeFiles = [];

    final pcregrepProcess = Process.runSync(
      'pcregrep',
      ['-r', '-M', "(?s)@GenerateMocks(.*?)]", path.join(Utils.projectDirectory, 'test')],
      runInShell: true,
    );
    final grepOutput = pcregrepProcess.stdout.toString().replaceAll(',\n', ',').replaceFirst('([\n', '([');

    final lines = grepOutput.trim().split('\n');
    final files = lines.map(_formatOutput);

    for (final file in files) {
      final dependentFiles = file.split(' ').map((d) => d.trim()).toList();
      codeFiles.add(
        CodeFile(
          path: dependentFiles[0],
          digest: Utils.calculateTestFileDigestFor(dependentFiles),
          isTestFile: true,
        ),
      );
    }

    Logger.log('Found ${codeFiles.length} files in "test/" that needs code generation');

    return codeFiles;
  }

  /// this method returns all the files that needs code generations
  List<CodeFile> _fetchFilePathsFromLib() {
    /// Files in "lib/" that needs code generation
    final libRegExp = RegExp(r"part '.+\.g\.dart';");

    final libProcess = Process.runSync(
      'grep',
      ['-r', '-l', '-E', libRegExp.pattern, path.join(Utils.projectDirectory, 'lib')],
      runInShell: true,
    );

    final libPathList = libProcess.stdout.toString().split("\n").where(
          (line) => line.isNotEmpty && !line.endsWith(".g.dart"),
        );

    Logger.log('Found ${libPathList.length} files in "lib/" that needs code generation');

    return libPathList
        .map<CodeFile>(
          (path) => CodeFile(
            path: path,
            digest: Utils.calculateDigestFor(path),
          ),
        )
        .toList();
  }

  /// copies the generated files to cache directory, and make an entry in database
  void _cacheGeneratedCodesFor(List<CodeFile> files) async {
    Utils.logHeader('CACHING NEWLY GENERATED CODES (${files.length})');

    for (final file in files) {
      Logger.log('Caching generated code for: ${Utils.getFileName(file.path)}');
      final cachedFilePath = path.join(Utils.appCacheDirectory, file.digest);
      final process = Process.runSync(
        'cp',
        [
          _getGeneratedFilePathFrom(file),
          cachedFilePath,
        ],
      );

      if (process.stderr.toString().isNotEmpty) {
        Logger.log('ERROR: _copyGeneratedCodesFor: ${process.stderr}', fatal: true);
      }

      /// if file has been successfully copied, let's make an entry to the db
      if (File(cachedFilePath).existsSync()) {
        await _databaseService.createEntry(file.digest, cachedFilePath);
      } else {
        Logger.log('ERROR: _cacheGeneratedCodesFor: failed to copy generated file $file', fatal: true);
      }
    }
  }
}
