import 'package:cached_build_runner/cached_build_runner.dart';
import 'package:cached_build_runner/core/build_runner_wrapper.dart';
import 'package:cached_build_runner/core/cache_provider.dart';
import 'package:cached_build_runner/core/dependency_visitor.dart';
import 'package:cached_build_runner/core/file_parser.dart';
import 'package:cached_build_runner/database/database_factory.dart';
import 'package:get_it/get_it.dart';

class DiContainer {
  static void setup() {
    GetIt.instance
      ..registerSingleton(DependencyVisitor())
      ..registerFactory<DatabaseFactory>(HiveDatabaseFactory.new)
      ..registerFactory(FileParser.new)
      ..registerFactory(CachedBuildRunner.new)
      ..registerFactory(BuildRunnerWrapper.new)
      ..registerSingleton(CacheProvider());
  }
}
