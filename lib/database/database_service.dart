import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;
import 'package:redis/redis.dart';

import '../utils/log.dart';
import '../utils/utils.dart';

/// An interface for a database service used to cache generated code.
abstract class DatabaseService {
  /// Initializes the database service.
  Future<void> init();

  /// Checks if the mapping is available for the given digests in bulk.
  FutureOr<Map<String, bool>> isMappingAvailableForBulk(
    Iterable<String> digests,
  );

  /// Checks if the mapping is available for the given digest.
  FutureOr<bool> isMappingAvailable(String digest);

  /// Gets the cached file path for the given digests in bulk.
  FutureOr<Map<String, String>> getCachedFilePathForBulk(
    Iterable<String> digests,
  );

  /// Gets the cached file path for the given digest.
  FutureOr<String> getCachedFilePath(String digest);

  /// Creates entries for the given cached file paths in bulk.
  Future<void> createEntryForBulk(Map<String, String> cachedFilePaths);

  /// Creates an entry for the given digest and cached file path.
  Future<void> createEntry(String digest, String cachedFilePath);

  /// Flushes the database service. Flushing to disk, or closing network connections
  /// could be done here.
  Future<void> flush();
}

/// An implementation of [DatabaseService] using Redis.
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
    _command.pipe_end();
    await _connection.close();
  }

  @override
  FutureOr<String> getCachedFilePath(String digest) async {
    final data = _cache[digest];
    if (data == null) {
      throw Exception(
        '$_tag: getCachedFilePath: asked path for non existing digest',
      );
    }

    return data;
  }

  File _generateConfigurationFile() {
    final configuration = """
# Redis configuration file

# Specify the directory where Redis will store its data
dir ${Utils.appCacheDirectory}

# Specify the save duration to disk: save <seconds> <changes>
# this saves to disk every 1 min if at least 1 key has changed
save 60 1
""";

    final configurationFile = File(
      path.join(Utils.appCacheDirectory, 'redis.conf'),
    );
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
      Logger.v('Redis started with PID ${process.pid}');

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

  @override
  Future<void> createEntryForBulk(Map<String, String> cachedFilePaths) async {
    final transaction = await _command.multi();
    final futures = <Future<dynamic>>[];

    for (final cache in cachedFilePaths.entries) {
      futures.add(transaction.set(cache.key, cache.value));
    }

    final response = await transaction.exec();
    if (response.toString() == 'OK') {
      await Future.wait(futures);
    } else {
      throw Exception('$_tag: createEntryForBulk: Redis Error $response');
    }
  }

  @override
  FutureOr<Map<String, String>> getCachedFilePathForBulk(
    Iterable<String> digests,
  ) {
    for (final digest in digests) {
      if (!_cache.containsKey(digest)) {
        throw Exception(
          '$_tag: getCachedFilePathForBulk: asked path for non existing digest: $digest',
        );
      }
    }
    return _cache;
  }

  Future<Map<String, String?>> _waitMapFutures(
    Map<String, Future<dynamic>> map,
  ) async {
    final result = <String, String?>{};
    final keys = map.keys.toList();
    final values = await Future.wait(map.values);
    for (int i = 0; i < keys.length; i++) {
      result[keys[i]] = values[i];
    }
    return result;
  }

  @override
  FutureOr<Map<String, bool>> isMappingAvailableForBulk(
    Iterable<String> digests,
  ) async {
    final transaction = await _command.multi();

    final futures = <String, Future<dynamic>>{};

    for (final digest in digests) {
      futures[digest] = transaction.get(digest);
    }

    late Map<String, String?> data;

    final response = await transaction.exec();
    if (response.toString() == 'OK') {
      data = await _waitMapFutures(futures);

      _cache.clear();
      for (var entry in data.entries) {
        if (entry.value != null) _cache[entry.key] = entry.value!;
      }
    } else {
      throw Exception(
        '$_tag: isMappingAvailableForBulk: Redis Error $response',
      );
    }

    return data.map((key, value) => MapEntry(key, value != null));
  }
}

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
}
