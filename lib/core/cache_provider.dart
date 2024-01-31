import 'dart:io';

import 'package:cached_build_runner/database/database_factory.dart';
import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;

typedef CachedFilesResult = ({List<CodeFile> good, List<CodeFile> bad});

class CacheProvider {
  final DatabaseFactory _databaseFactory;

  DatabaseService? __database;

  Future<DatabaseService> get _database async {
    final dbInstance = __database;
    if (dbInstance == null) {
      final db = await _databaseFactory.create();
      __database = db;

      return db;
    }

    return dbInstance;
  }

  CacheProvider({DatabaseFactory? databaseFactory}) : _databaseFactory = databaseFactory ?? GetIt.I<DatabaseFactory>();

  Future<void> ensurePruning() async {
    if (!Utils.isPruneEnabled) return;

    final database = await _database;

    Logger.i('Prunning is enabled - checking pubpsec.lock');

    final pubspecLockPath = path.join(Utils.projectDirectory, Constants.pubpsecLockFileName);
    final pubspecLock = File(pubspecLockPath);

    final fileExists = pubspecLock.existsSync();

    if (!fileExists) {
      Logger.e('No ${Constants.pubpsecLockFileName} exits');

      return;
    }

    final digest = DigestUtils.generateDigestForSingleFile(pubspecLockPath);

    final existingDigest = await database.getEntryByKey(Constants.pubpsecLockFileName);

    Logger.v('Pubspec.lock digest: $digest');
    Logger.v('Existing Pubspec.lock digest: $digest');
    Logger.v('Will prune? ${digest != existingDigest ? 'YES' : 'NO'}');

    if (existingDigest != null && digest != existingDigest) {
      Logger.i('!!! Pruning cache as pubspec.lock was changed from last time !!!');
      await database.prune(keysToKeep: [Constants.pubpsecLockFileName]);
    }

    await _dbOperation((db) => db.createCustomEntry(Constants.pubpsecLockFileName, digest));
  }

  Future<CachedFilesResult> mapFilesToCache(List<CodeFile> files) async {
    final goodFiles = <CodeFile>[];
    final badFiles = <CodeFile>[];

    final bulkMapping = await _dbOperation(
      (db) async => await db.isMappingAvailableForBulk(
        files.map((f) => f.digest),
      ),
    );

    /// segregate good and bad files
    /// good files -> files for whom the generated codes are available
    /// bad files -> files for whom no generated codes are available in the cache
    for (final file in files) {
      final isGeneratedCodeAvailable = bulkMapping[file.digest] ?? false;

      /// mock generated files are always considered badFiles,
      /// as they depends on various services, and to keep track of changes can become complicated
      if (isGeneratedCodeAvailable) {
        goodFiles.add(file);
      } else {
        badFiles.add(file);
      }
    }

    return (good: goodFiles, bad: badFiles);
  }

  Future<void> cacheFiles(List<CodeFile> files) async {
    if (files.isEmpty) {
      return Logger.header('No new files to cache');
    }

    Logger.header('Caching ${files.length} files');

    final cacheEntry = <String, String>{};

    for (final file in files) {
      final generatedCodeFile = File(file.getGeneratedFilePath());
      Logger.v('Caching: ${Utils.getFileName(generatedCodeFile.path)}');

      final cachedFilePath = path.join(Utils.appCacheDirectory, file.digest);
      if (generatedCodeFile.existsSync()) {
        final _ = generatedCodeFile.copySync(cachedFilePath);
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
    await _dbOperation((db) => db.createEntryForBulk(cacheEntry));
  }

  Future<void> copyGeneratedCodesFor(List<CodeFile> files) async {
    Logger.i('Copying cached files to project directory (${files.length} total)');

    for (final file in files) {
      final cachedGeneratedCodePath = await _dbOperation(
        (db) async => await db.getCachedFilePath(file.digest),
      );
      final generatedFilePath = file.getGeneratedFilePath();

      Logger.v('Copying file: ${Utils.getFileName(generatedFilePath)}');
      final copiedFile = File(cachedGeneratedCodePath).copySync(generatedFilePath);

      /// check if the file was copied successfully
      if (!copiedFile.existsSync()) {
        Logger.e(
          'ERROR: _copyGeneratedCodesFor: failed to copy the cached file $file',
        );
      }
    }
  }

  Future<void> prune() {
    return _dbOperation((db) => db.prune(keysToKeep: []));
  }

  Future<Map<String, String>> listCachedFiles() {
    return _dbOperation((db) => db.getAllData());
  }

  Future<T> _dbOperation<T>(Transaction<T> op) async {
    final db = await _database;

    return db.transaction(op);
  }
}
