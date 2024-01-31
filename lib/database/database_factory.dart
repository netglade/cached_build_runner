import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/database/hive_database_service.dart';
import 'package:cached_build_runner/utils/utils.dart';

// ignore: one_member_abstracts, it is ok
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
