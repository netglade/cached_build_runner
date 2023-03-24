import 'dart:io';

import 'package:args/args.dart';
import 'package:cached_build_runner/cached_build_runner.dart'
    as cached_build_runner;
import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/utils/log.dart';
import 'package:cached_build_runner/utils/utils.dart';

/// parser argument flags & options
const help = 'help';
const quiet = 'quiet';
const useRedis = 'redis';
const generateTestMocks = 'generate-test-mock';
const cacheDirectory = 'cache-directory';
const projectDirectory = 'project-directory';

Future<void> main(List<String> arguments) async {
  /// parse args
  _parseArgs(arguments);

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
  final buildCache = cached_build_runner.CachedBuildRunner(databaseService);
  await buildCache.build();
}

void _parseArgs(List<String> args) {
  final parser = ArgParser()
    ..addFlag(help,
        abbr: 'h', help: 'Print out usage instructions.', negatable: false)
    ..addFlag(
      quiet,
      abbr: 'q',
      help: 'Disables printing out logs during build.',
      negatable: false,
    )
    ..addFlag(
      generateTestMocks,
      abbr: 't',
      help:
          'Generates mocks for test files, if this flag is not provided mock generations are skipped.',
      negatable: false,
    )
    ..addFlag(
      useRedis,
      abbr: 'r',
      help:
          'Use redis database, if installed on the system. Using redis allows multiple instance access. Ideal for usage in pipelines. Default implementation uses a file system storage (hive), which is idea for usage in local systems.',
      negatable: false,
    )
    ..addSeparator('')
    ..addOption(
      cacheDirectory,
      abbr: 'c',
      help: 'Provide the directory where this tool can keep the caches.',
    )
    ..addOption(
      projectDirectory,
      abbr: 'p',
      help: 'Provide the directory of the project.',
    );

  final result = parser.parse(args);

  if (result.wasParsed(help)) {
    Logger.i('''
cached_build_runner: Optimizes the build_runner by caching generated codes for non changed .dart files.

${parser.usage}
''');
    exit(0);
  }

  if (result.wasParsed(cacheDirectory)) {
    Utils.appCacheDirectory = result[cacheDirectory];
  } else {
    Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
    Logger.i(
      "As no '$cacheDirectory' was specified, using the default directory: ${Utils.appCacheDirectory}",
    );
  }

  if (result.wasParsed(projectDirectory)) {
    Utils.projectDirectory = result[projectDirectory];
  } else {
    Utils.projectDirectory = Utils.getDefaultProjectDirectory();
    Logger.i(
      "As no '$projectDirectory' was specified, using the current directory: ${Utils.projectDirectory}",
    );
  }

  Utils.isVerbose = !result.wasParsed(quiet);
  Utils.generateTestMocks = result.wasParsed(generateTestMocks);
  Utils.isRedisUsed = result.wasParsed(useRedis);
}
