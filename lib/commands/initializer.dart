import 'dart:io';

import '../cached_build_runner.dart';
import '../database/database_service.dart';
import '../utils/utils.dart';

/// This class configures the CachedBuildRunner as per the arguments parsed.
/// And also initializes any variables, or create cache directory if non-existing.
class Initializer {
  Future<CachedBuildRunner> init() async {
    /// let's make the appCacheDirectory if not existing already
    Directory(Utils.appCacheDirectory).createSync(recursive: true);

    /// init package name of project
    Utils.initAppPackageName();

    /// initialize the database
    final databaseService = Utils.isRedisUsed
        ? RedisDatabaseService()
        : HiveDatabaseService(Utils.appCacheDirectory);
    await databaseService.init();

    /// let's initiate the build
    return CachedBuildRunner(databaseService);
  }
}
