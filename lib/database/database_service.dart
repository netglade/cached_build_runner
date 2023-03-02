import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;

abstract class DatabaseService {
  Future<void> init(String dirPath);
  bool isMappingAvailable(String digest);
  String getCachedFilePath(String digest);
  Future<void> createEntry(String digest, String cachedFilePath);
}

class HiveDatabaseService implements DatabaseService {
  static const _dbName = 'build_cache_db';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

  @override
  Future<void> init(String dirPath) async {
    Hive.init(dirPath);
    Hive.init(path.join(_dbName, _dbName));
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  bool isMappingAvailable(String digest) {
    // TODO: implement mappingExists
    throw UnimplementedError();
  }

  @override
  String getCachedFilePath(String digest) {
    // TODO: implement getCachedFilePath
    throw UnimplementedError();
  }

  @override
  Future<void> createEntry(String digest, String cachedFilePath) {
    // TODO: implement createEntry
    throw UnimplementedError();
  }
}
