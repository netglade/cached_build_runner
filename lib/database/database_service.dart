import 'package:hive/hive.dart';

import '../utils/utils.dart';

abstract class DatabaseService {
  Future<void> init(String dirPath);
  bool isMappingAvailable(String digest);
  String getCachedFilePath(String digest);
  Future<void> createEntry(String digest, String cachedFilePath);
  Future<void> flush();
}

class HiveDatabaseService implements DatabaseService {
  static const _tag = 'HiveDatabaseService';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

  @override
  Future<void> init(String dirPath) async {
    Hive.init(dirPath);
    Hive.init(Utils.appCacheDirectory);
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  bool isMappingAvailable(String digest) {
    return _box.containsKey(digest);
  }

  @override
  String getCachedFilePath(String digest) {
    final filePath = _box.get(digest);
    if (filePath == null) {
      throw Exception('$_tag: getCachedFilePath: asked path for non existing digest');
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
}
