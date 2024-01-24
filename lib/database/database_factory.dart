import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/database/hive_database_service.dart';
import 'package:cached_build_runner/utils/utils.dart';

abstract class DatabaseFactory {
  Future<DatabaseService> create();
}

class HiveDatabaseFactory extends DatabaseFactory {
  @override
  Future<DatabaseService> create() async {
    final service = HiveDatabaseService(Utils.appCacheDirectory);

    await service.init();

    return service;
  }
}
