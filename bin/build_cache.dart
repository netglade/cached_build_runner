import 'dart:io';

import 'package:build_cache/build_cache.dart' as build_cache;
import 'package:build_cache/database/database_service.dart';
import 'package:build_cache/utils/log.dart';
import 'package:build_cache/utils/utils.dart';

Future<void> main(List<String> arguments) async {
  final startTime = DateTime.now();

  /// TODO: let's improve the arguments handling

  if (arguments.length == 2) {
    Utils.appCacheDirectory = arguments[0];
    Utils.projectDirectory = arguments[1];
  } else {
    /// TODO: throw error, with correct message
  }

  /// let's make the appCacheDirectory if not existing already
  Directory(Utils.appCacheDirectory).createSync(recursive: true);

  /// initialize the database
  final databaseService = HiveDatabaseService();
  await databaseService.init(Utils.appCacheDirectory);

  /// let's initiate the build
  final buildCache = build_cache.BuildCache(databaseService);
  await buildCache.build();

  final timeTook = DateTime.now().difference(startTime);
  Utils.logHeader('Code Generation took: $timeTook');
}
