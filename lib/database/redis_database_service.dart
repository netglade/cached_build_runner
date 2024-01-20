import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:redis/redis.dart';

import '../utils/log.dart';
import '../utils/utils.dart';
import 'database_service.dart';

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

  @override
  Future<void> createCustomEntry(String key, String entry) {
    return _command.set(key, entry);
  }

  @override
  Future<String?> getEntryByKey(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final resp = await _command.get(key);
    if (resp != null) {
      _cache[key] = resp.toString();

      return resp.toString();
    }

    return null;
  }

  @override
  Future<void> prune({required List<String> keysToKeep}) async {
    final data = <String, dynamic>{};

    for (final key in keysToKeep) {
      data[key] = await _command.get(key);
    }

    await _command.send_object(['FLUSHDB']);

    for (final key in keysToKeep) {
      await _command.set(key, data[key]);
    }
  }
}
