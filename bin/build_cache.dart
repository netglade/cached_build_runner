import 'package:build_cache/build_cache.dart' as build_cache;
import 'package:build_cache/database/database_service.dart';
import 'package:build_cache/utils/utils.dart';

Future<void> main(List<String> arguments) async {
  /// TODO: let's improve the arguments handling

  if (arguments.length == 2) {
    Utils.appCacheDirectory = arguments[0];
    Utils.projectDirectory = arguments[1];
  } else {
    /// TODO: throw error, with correct message
  }

  /// initialize the database
  final databaseService = HiveDatabaseService();
  await databaseService.init(Utils.appCacheDirectory);

  /// let's initiate the build
  final buildCache = build_cache.BuildCache(databaseService);
  return buildCache.build();
}
