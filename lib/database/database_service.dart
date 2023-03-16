import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:redis/redis.dart';

import '../utils/log.dart';
import '../utils/utils.dart';

abstract class DatabaseService {
  Future<void> init();
  FutureOr<bool> isMappingAvailable(String digest);
  FutureOr<String> getCachedFilePath(String digest);
  Future<void> createEntry(String digest, String cachedFilePath);
  Future<void> flush();
}

class RedisDatabaseService implements DatabaseService {
  static const _tag = 'RedisDatabaseService';

  static const _redisHost = 'localhost';
  static const _redisPort = 6379;

  late RedisConnection _connection;
  late Command _command;

  final Map<String, String> _cache = {};

  @override
  Future<void> createEntry(String digest, String cachedFilePath) async {
    _command.set(digest, cachedFilePath);
  }

  @override
  Future<void> flush() async {
    /// a short delay to make sure all network connections are done before we close the connection
    await Utils.delay500ms();
    _command.pipe_end();
    await _connection.close();
  }

  @override
  FutureOr<String> getCachedFilePath(String digest) async {
    final data = _cache[digest];
    if (data == null) {
      throw Exception('$_tag: getCachedFilePath: asked path for non existing digest');
    }

    return data;
  }

  File _generateConfigurationFile() {
    final configuration = """
# Redis configuration file

# Specify the directory where Redis will store its data
dir ${Utils.appCacheDirectory}
""";

    final configurationFile = File(path.join(Utils.appCacheDirectory, 'redis.conf'));
    configurationFile.writeAsStringSync(configuration);
    return configurationFile;
  }

  @override
  Future<void> init() async {
    final configurationPath = _generateConfigurationFile();
    _connection = RedisConnection();
    try {
      _command = await _connection.connect(_redisHost, _redisPort);
    } on SocketException catch (_) {
      final process = await Process.start(
        'redis-server',
        [configurationPath.path],
        mode: ProcessStartMode.detached,
      );
      Logger.log('Redis started with PID ${process.pid}');

      /// assumption: redis would fire up within this delayed duration
      await Utils.delay500ms();
      _command = await _connection.connect(_redisHost, _redisPort);
    }

    _command.pipe_start();
  }

  @override
  FutureOr<bool> isMappingAvailable(String digest) async {
    final resp = await _command.get(digest);
    if (resp != null) {
      _cache[digest] = resp.toString();
      return true;
    }

    return false;
  }
}

class HiveDatabaseService implements DatabaseService {
  final String dirPath;

  HiveDatabaseService(this.dirPath);

  static const _tag = 'HiveDatabaseService';
  static const _boxName = 'generated-file-box';

  late Box<String> _box;

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
