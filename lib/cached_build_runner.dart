/// This library contains the [CachedBuildRunner] class that provides an efficient way to run `build_runner build`
/// by determining the files that need code generation and generating only the required code files. It uses caching
/// to avoid unnecessary generation builds and only generates codes for files that don't have cached versions.
///
/// Imports:
///
///   - `dart:io` for file I/O operations.
///   - `package:path/path.dart` for path manipulation.
///   - `database/database_service.dart` for interacting with the database service. Redis for running multiple instances
///      (such as in a pipeline) and hive if a single instance is using (such as in dev environment)
///   - `model/code_file.dart` for the [CodeFile] class that represents a code file.
///   - `utils/log.dart` for logging messages to the console.
///   - `utils/utils.dart` for utility functions.

library cached_build_runner;

import 'dart:async';
import 'dart:io';

import 'package:cached_build_runner/core/dependency_visitor.dart';
import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/extension.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart' as sync;

import 'database/database_service.dart';
import 'model/code_file.dart';
import 'utils/log.dart';
import 'utils/utils.dart';

class CachedBuildRunner {
  final DatabaseService _databaseService;

  CachedBuildRunner(this._databaseService);

  final Map<String, String> _contentDigestMap = {};
  final _buildLock = sync.Lock();

  final _dependencyVisitor = DependencyVisitor();

  bool _isCodeGenerationNeeded(FileSystemEvent e) {
    switch (e.type) {
      case FileSystemEvent.modify:
        final newDigest = DigestUtils.generateDigestForSingleFile(e.path);
        if (newDigest != _contentDigestMap[e.path]) {
          _contentDigestMap[e.path] = newDigest;
          return true;
        }
        return false;

      case FileSystemEvent.move:
      case FileSystemEvent.create:
        final digest = DigestUtils.generateDigestForSingleFile(e.path);
        _contentDigestMap[e.path] = digest;
        return true;

      case FileSystemEvent.delete:
        _contentDigestMap.remove(e.path);
        return true;
    }

    return false;
  }

  void _synchronizedBuild() {
    _buildLock.synchronized(build);
  }

  void _onFileSystemEvent(FileSystemEvent event) {
    if (_isCodeGenerationNeeded(event)) {
      _synchronizedBuild();
    }
  }

  void _generateContentHash(Directory directory) {
    if (!directory.existsSync()) return;
    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.isDartSourceCodeFile()) {
        _contentDigestMap[entity.path] = DigestUtils.generateDigestForSingleFile(
          entity.path,
        );
      }
    }
  }

  void _watchForDependencyChanges() {
    final pubspecFile = File(path.join(Utils.projectDirectory, 'pubspec.yaml'));
    final pubspecFileDigest = DigestUtils.generateDigestForSingleFile(
      pubspecFile.path,
    );

    pubspecFile.watch().listen((event) {
      final newPubspecFileDigest = DigestUtils.generateDigestForSingleFile(
        event.path,
      );

      if (newPubspecFileDigest != pubspecFileDigest) {
        Logger.i(
          'As pubspec.yaml file has been modified, terminating cached_build_runner.\nNo further builds will be scheduled. Please restart the build.',
        );
        exit(0);
      }
    });
  }

  Future<void> watch() async {
    _watchForDependencyChanges();

    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));
    final testDirectory = Directory(path.join(Utils.projectDirectory, 'test'));

    Utils.logHeader(
      'Preparing to watch files in directory: ${Utils.projectDirectory}',
    );

    _generateContentHash(libDirectory);
    _generateContentHash(testDirectory);

    /// perform a first build operation
    await build();

    Utils.logHeader('Watching for file changes.');

    /// let's listen for file changes in the project directory
    /// specifically in "lib" & "test" directory
    libDirectory.watchDartSourceCodeFiles().listen(_onFileSystemEvent);
    testDirectory.watchDartSourceCodeFiles().listen(_onFileSystemEvent);
  }

  /// Runs an efficient version of `build_runner build` by determining which
  /// files need code generation and then either retrieving cached files,
  /// generating new files, or caching new generated files.
  ///
  /// To determine which files need code generation, this method first fetches
  /// all the Dart files in the `lib` directory and any test files in the
  /// `test` directory that contain the `@Generate` annotation.
  ///
  /// It then checks the database to see if generated files are available for
  /// these files. If so, it copies the cached files to their appropriate
  /// location in the project directory. If not, it generates the necessary
  /// files and caches them for future use.
  ///
  /// Finally, if Hive is used, it flushes Hive to ensure that everything is committed to disk.
  /// Otherwise, closes any connection open to Redis.
  ///
  ///   Throws:
  ///
  ///   - [Exception] if there is an error while running `build_runner build` command.

  Future<void> build() async {
    Utils.logHeader('Determining Files that needs code generation');

    await _checkPrunning();

    final libFiles = _fetchFilePathsFromLib();
    final testFiles = await _fetchFilePathsFromTest();
    final files = List<CodeFile>.from(libFiles)..addAll(testFiles);

    final List<CodeFile> goodFiles = [];
    final List<CodeFile> badFiles = [];

    final bulkMapping = await _databaseService.isMappingAvailableForBulk(
      files.map((f) => f.digest),
    );

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
    Logger.v('No. of non-cached files: ${badFiles.length}\n${badFiles.join('\n')}');

    /// let's handle bad files - by generating the .g.dart / .mocks.dart files for them
    final success = _generateCodesFor(badFiles);
    if (!success) return;

    /// let's handle the good files - by copying the cached generated files to appropriate path
    await _copyGeneratedCodesFor(goodFiles);

    /// at last, let's cache the bad files - they may be required next time
    await _cacheGeneratedCodesFor(badFiles);

    /// let's flush Hive, to make sure everything is committed to disk
    await _databaseService.flush();

    /// We are done, probably?
  }

  Future<void> _checkPrunning() async {
    if (!Utils.isPruneEnabled) return;

    Logger.v('Prunning is enabled - checking pubpsec.lock');

    final pubspecLockPath = path.join(Utils.projectDirectory, Constants.pubpsecLock);
    final pubspecLock = File(pubspecLockPath);

    final fileExists = await pubspecLock.exists();

    if (!fileExists) {
      Logger.e('No ${Constants.pubpsecLock} exits');

      return;
    }

    final digest = DigestUtils.generateDigestForSingleFile(pubspecLockPath);

    final existingDigest = await _databaseService.getEntryByKey(Constants.pubpsecLock);

    Logger.v(
        'Pubspec.lock digest: $digest vs existing Pubspec.lock digest: $digest | Will prune? ${digest != existingDigest}');

    if (existingDigest != null && digest != existingDigest) {
      Logger.v('!!! Pruning cache as pubspec.lock was changed from last time !!!');
      await _databaseService.prune(keysToKeep: [Constants.pubpsecLock]);
    }

    await _databaseService.createCustomEntry(Constants.pubpsecLock, digest);
  }

  /// Copies the cached generated files to the project directory for the given files list.
  /// The cached file paths are obtained from the DatabaseService for the given files.
  /// The method uses the _getGeneratedFilePathFrom() method to get the file path where
  /// the generated file should be copied to in the project directory.
  Future<void> _copyGeneratedCodesFor(List<CodeFile> files) async {
    Utils.logHeader('Copying cached codes to project directory');

    for (final file in files) {
      final cachedGeneratedCodePath = await _databaseService.getCachedFilePath(
        file.digest,
      );
      Logger.v(
        'Copying file: ${Utils.getFileName(_getGeneratedFilePathFrom(file))}',
      );
      File(cachedGeneratedCodePath).copySync(_getGeneratedFilePathFrom(file));

      /// check if the file was copied successfully
      if (!File(_getGeneratedFilePathFrom(file)).existsSync()) {
        Logger.e(
          'ERROR: _copyGeneratedCodesFor: failed to copy the cached file $file',
        );
      }
    }
  }

  /// converts "./cta_model.dart" to "./cta_model.g.dart"
  /// OR
  /// converts "./otp_screen_test.dart" to "./otp_screen_test.mocks.dart";
  String _getGeneratedFilePathFrom(CodeFile file) {
    final path = file.path;
    final lastDotDart = path.lastIndexOf('.dart');
    final extension = file.isTestFile ? '.mocks.dart' : '.${file.suffix ?? 'g'}.dart';

    if (lastDotDart >= 0) {
      return '${path.substring(0, lastDotDart)}$extension';
    }

    return path;
  }

  /// Returns a comma-separated string of the file paths from the given list of [CodeFile]s
  /// formatted for use as the argument for the --build-filter flag in the build_runner build command.
  ///
  /// The method maps the list of [CodeFile]s to a list of generated file paths, and then
  /// returns a comma-separated string of the generated file paths.
  ///
  /// For example:
  ///
  /// final files = [CodeFile(path: 'lib/foo.dart', digest: 'abc123')];
  /// final buildFilter = _getBuildFilterList(files);
  /// print(buildFilter); // 'lib/foo.g.dart'
  String _getBuildFilterList(List<CodeFile> files) {
    final paths = files.map<String>((codeFile) => _getGeneratedFilePathFrom(codeFile)).toList();
    return paths.join(',');
  }

  /// this method runs build_runner build method with --build-filter
  /// to only generate the required codes, thus avoiding unnecessary builds
  bool _generateCodesFor(List<CodeFile> files) {
    if (files.isEmpty) return true;
    Utils.logHeader(
      'Generating Codes for non-cached files, found ${files.length} files',
    );

    /// following command needs to be executed
    /// flutter pub run build_runner build --build-filter="..." -d
    /// where ... contains the list of files that needs generation
    Logger.v('Running build_runner build...', showPrefix: false);

    final filterList = _getBuildFilterList(files);
    Logger.v(filterList, showPrefix: false);

    /// TODO: let's check how we can use the build_runner package and include in this project
    /// instead of relying on the flutter pub run command
    /// there can be issues with flutter being in the path.
    final process = Process.runSync(
      'flutter',
      [
        'pub',
        'run',
        'build_runner',
        'build',
        '--build-filter',
        _getBuildFilterList(files),
        //  '--delete-conflicting-outputs',
      ],
      workingDirectory: Utils.projectDirectory,
    );

    if (process.stderr.toString().isNotEmpty) {
      if (process.stdout.toString().isNotEmpty) Logger.e(process.stdout.trim());
      Logger.e(process.stderr.trim());
      return false;
    } else {
      Logger.v(process.stdout.trim(), showPrefix: false);
      return true;
    }
  }

  /// Fetches all the Dart test files in the 'test/' directory that contain the @Generate annotation for code generation.
  /// Generates the [CodeFile] object for each file, which includes the file path, the MD5 digest of the file
  /// and a flag indicating that it's a test file.
  /// If the generateTestMocks flag in [Utils] is false, returns an empty list.
  /// Searches for the dependencies of each test file in the 'test/' directory recursively, and adds them to the
  /// dependencies list. If a dependency is from the main library, the dependency file is added to the list.
  /// If there are no dependencies, the test file is skipped.
  /// Returns a list of [CodeFile] objects representing all the test files in the 'test/' directory
  /// that need code generation.
  Future<List<CodeFile>> _fetchFilePathsFromTest() async {
    final List<List<String>> testFiles = [];

    final testDirectory = Directory(path.join(Utils.projectDirectory, 'test'));
    if (!testDirectory.existsSync()) return const [];

    for (FileSystemEntity entity in testDirectory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      final List<String> dependencies = [];

      if (entity is File && entity.isDartSourceCodeFile()) {
        final filePath = entity.path.trim();
        final fileContent = entity.readAsStringSync();

        /// if the file doesn't contain `@Generate` string, meaning no annotation for generations were marked
        /// thus we can safely assume we don't need to generate mocks for those files
        if (!fileContent.contains('@Generate')) continue;

        dependencies.add(filePath);

        final importDependency = _dependencyVisitor.convertImportStatementsToAbsolutePaths(
          fileContent,
        );

        dependencies.addAll(importDependency);
        testFiles.add(dependencies);
      }
    }

    final List<CodeFile> codeFiles = [];

    for (final files in testFiles) {
      codeFiles.add(
        CodeFile(
          path: files[0],
          digest: DigestUtils.generateDigestForMultipleClassFile(
            _dependencyVisitor,
            files,
          ),
          suffix: null,
          isTestFile: true,
        ),
      );
    }

    Logger.v(
      'Found ${codeFiles.length} files in "test/" that needs code generation',
    );

    return codeFiles;
  }

  /// This method returns all the files in the 'lib/' directory that need code generation. It first identifies the files
  /// containing part '.g.dart'; statements using a regular expression. It then uses the grep command to find those
  /// files and exclude any files that already have a .g.dart extension. Finally, it maps the file paths to a list of
  /// CodeFile instances, which contains the file path and its corresponding digest calculated using the Utils.calculateDigestFor
  /// method.
  ///
  /// Returns a list of [CodeFile] instances that represent the files that need code generation.
  List<CodeFile> _fetchFilePathsFromLib() {
    /// Files in "lib/" that needs code generation
    final partRegExp = RegExp(r"part '.+\.(.+)\.dart';");
    final importRegExp = RegExp(r"import '.+\.([^g].*|g.+)\.dart';");
    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));

    final List<({String path, String? suffix})> libPathList = [];

    for (final entity in libDirectory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.isDartSourceCodeFile()) {
        final filePath = entity.path.trim();
        final fileContent = entity.readAsStringSync();

        final partMatch = partRegExp.firstMatch(fileContent);
        if (partMatch != null) {
          libPathList.add((path: filePath, suffix: partMatch.group(1)));
        }

        final importMatch = importRegExp.firstMatch(fileContent);
        if (importMatch != null) {
          libPathList.add((path: filePath, suffix: importMatch.group(1)));
        }
      }
    }

    Logger.v(
      'Found ${libPathList.length} files in "lib/" that needs code generation',
    );

    return libPathList
        .map<CodeFile>(
          (f) => CodeFile(
              path: f.path,
              digest: DigestUtils.generateDigestForClassFile(
                _dependencyVisitor,
                f.path,
              ),
              suffix: f.suffix),
        )
        .toList();
  }

  /// Copies the generated files from the project directory to cache directory, and make an entry in database.
  Future<void> _cacheGeneratedCodesFor(List<CodeFile> files) async {
    if (files.isEmpty) return;

    Utils.logHeader(
      'Caching new generated codes, caching ${files.length} files',
    );

    final cacheEntry = <String, String>{};

    for (final file in files) {
      final generatedCodeFile = File(_getGeneratedFilePathFrom(file));
      Logger.v(
        'Caching generated code for: ${Utils.getFileName(generatedCodeFile.path)}',
      );
      final cachedFilePath = path.join(Utils.appCacheDirectory, file.digest);
      if (generatedCodeFile.existsSync()) {
        generatedCodeFile.copySync(cachedFilePath);
      } else {
        continue;
      }

      /// if file has been successfully copied, let's make an entry to the db
      if (File(cachedFilePath).existsSync()) {
        cacheEntry[file.digest] = cachedFilePath;
      } else {
        Logger.e(
          'ERROR: _cacheGeneratedCodesFor: failed to copy generated file $file',
        );
      }
    }

    /// create a bulk entry
    await _databaseService.createEntryForBulk(cacheEntry);
  }
}
