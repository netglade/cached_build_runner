import 'dart:async';

import 'package:hive/hive.dart';

import 'database_service.dart';

/// An implementation of [DatabaseService] using Hive.
class HiveDatabaseService implements DatabaseService {
  final String dirPath;

  HiveDatabaseService(this.dirPath);

  static const _tag = 'HiveDatabaseService';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

  @override
  Future<void> init() async {
    Hive.init(dirPath);
    print('Hive: $dirPath');
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
    final Map<String, String> data = {};

    for (final digest in digests) {
      data[digest] = getCachedFilePath(digest) as String;
    }

    return data;
  }

  @override
  FutureOr<Map<String, bool>> isMappingAvailableForBulk(
    Iterable<String> digests,
  ) {
    final Map<String, bool> data = {};

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
    final saved = <String, dynamic>{};

    for (var key in keysToKeep) {
      saved[key] = _box.get(key);
    }

    _box.clear();

    for (var key in keysToKeep) {
      _box.put(key, saved[key]);
    }

    await flush();
  }
}
