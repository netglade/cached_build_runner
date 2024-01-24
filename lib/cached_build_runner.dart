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

import 'package:cached_build_runner/core/build_runner_wrapper.dart';
import 'package:cached_build_runner/core/cache_provider.dart';
import 'package:cached_build_runner/core/file_parser.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/extension.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;
import 'package:synchronized/synchronized.dart' as sync;

class CachedBuildRunner implements Disposable {
  final FileParser _fileParser;
  final CacheProvider _cacheProvider;
  final BuildRunnerWrapper _buildRunnerWrapper;

  final Map<String, String> _contentDigestMap = {};
  final _buildLock = sync.Lock();

  StreamSubscription<FileSystemEvent>? _pubpsecWatch;
  StreamSubscription<FileSystemEvent>? _libWatch;

  CachedBuildRunner({
    FileParser? fileParser,
    CacheProvider? cacheProvider,
    BuildRunnerWrapper? buildRunnerWrapper,
  })  : _fileParser = fileParser ?? GetIt.I<FileParser>(),
        _cacheProvider = cacheProvider ?? GetIt.I<CacheProvider>(),
        _buildRunnerWrapper = buildRunnerWrapper ?? GetIt.I<BuildRunnerWrapper>();

  Future<void> watch() async {
    _watchForDependencyChanges();

    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));

    Logger.header(
      'Preparing to watch files in directory: ${Utils.projectDirectory}',
    );

    _generateContentHash(libDirectory);

    /// perform a first build operation
    await build();

    Logger.header('Watching for file changes.');

    // let's listen for file changes in the project directory
    // specifically in "lib" irectory
    _libWatch = libDirectory.watchDartSourceCodeFiles().listen(_onFileSystemEvent);
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
    Logger.header('Determining Files that needs code generation');

    await _cacheProvider.ensurePruning();

    final libFiles = _fileParser.fetchFilePathsFromLib();
    final files = List<CodeFile>.of(libFiles);

    //..addAll(testFiles);

    final mappedResult = await _cacheProvider.mapFilesToCache(files);

    final goodFiles = mappedResult.good;
    final badFiles = mappedResult.bad;

    Logger.i('No. of cached files: ${goodFiles.length}');
    Logger.i('No. of non-cached files: ${badFiles.length}\n${badFiles.join('\n')}');

    /// let's handle bad files - by generating the .g.dart / .mocks.dart files for them
    final success = _buildRunnerWrapper.runBuild(badFiles);

    if (!success) return;

    /// let's handle the good files - by copying the cached generated files to appropriate path
    await _cacheProvider.copyGeneratedCodesFor(goodFiles);

    /// at last, let's cache the bad files - they may be required next time
    await _cacheProvider.cacheFiles(badFiles);

    /// We are done, probably?
  }

  @override
  Future<void> onDispose() async {
    await _pubpsecWatch?.cancel();
    await _libWatch?.cancel();
  }

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
        if (_contentDigestMap.containsKey(e.path)) {
          final _ = _contentDigestMap.remove(e.path);

          return true;
        }

        return false;
    }

    return false;
  }

  void _synchronizedBuild() {
    unawaited(_buildLock.synchronized(build));
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
        Logger.v('ContentDigest: ${entity.path}');
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

    _pubpsecWatch = pubspecFile.watch().listen((event) {
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
}

extension FileSystemEventExtensions on FileSystemEvent {
  String get name => switch (type) {
        FileSystemEvent.create => 'create',
        FileSystemEvent.move => 'move',
        FileSystemEvent.delete => 'delete',
        FileSystemEvent.modify => 'modify',
        _ => 'unknown $type',
      };
}
