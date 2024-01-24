import 'dart:async';

import 'package:cached_build_runner/database/database_service.dart';
import 'package:hive/hive.dart';

/// An implementation of [DatabaseService] using Hive.
class HiveDatabaseService implements DatabaseService {
  final String dirPath;

  static const _tag = 'HiveDatabaseService';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

  HiveDatabaseService(this.dirPath);

  @override
  Future<void> init() async {
    Hive.init(dirPath);
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  FutureOr<bool> isMappingAvailable(String digest) {
    return _box.containsKey(digest);
  }

  @override
  FutureOr<String> getCachedFilePath(String digest) {
    final filePath = _box.get(digest);
    if (filePath == null) {
      throw Exception(
        '$_tag: getCachedFilePath: asked path for non existing digest',
      );
    }

    return filePath;
  }

  @override
  Future<void> createEntry(String digest, String cachedFilePath) {
    return _box.put(digest, cachedFilePath);
  }

  @override
  Future<void> flush() {
    return _box.flush();
  }

  @override
  Future<void> createEntryForBulk(Map<String, String> cachedFilePaths) {
    return _box.putAll(cachedFilePaths);
  }

  @override
  FutureOr<Map<String, String>> getCachedFilePathForBulk(
    Iterable<String> digests,
  ) {
    final data = <String, String>{};

    for (final digest in digests) {
      data[digest] = getCachedFilePath(digest) as String;
    }

    return data;
  }

  @override
  FutureOr<Map<String, bool>> isMappingAvailableForBulk(
    Iterable<String> digests,
  ) {
    final data = <String, bool>{};

    for (final digest in digests) {
      data[digest] = isMappingAvailable(digest) as bool;
    }

    return data;
  }

  @override
  Future<void> createCustomEntry(String key, String entry) {
    return _box.put(key, entry);
  }

  @override
  Future<String?> getEntryByKey(String key) async {
    return _box.get(key);
  }

  @override
  Future<void> prune({required List<String> keysToKeep}) async {
    final saved = <String, String>{};

    for (final key in keysToKeep) {
      final value = _box.get(key);
      if (value != null) saved[key] = value;
    }

    final _ = await _box.clear();

    for (final key in keysToKeep) {
      await _box.put(key, saved[key]!);
    }

    await flush();
  }

  @override
  Future<T> transaction<T>(Transaction<T> transactionCallback) async {
    final result = await transactionCallback(this);

    await flush();

    return result;
  }
}
