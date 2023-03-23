import 'dart:io';

import 'package:args/args.dart';
import 'package:cached_build_runner/cached_build_runner.dart' as cached_build_runner;
import 'package:cached_build_runner/database/database_service.dart';
import 'package:cached_build_runner/utils/log.dart';
import 'package:cached_build_runner/utils/utils.dart';

/// parser argument flags & options
const help = 'help';
const verbose = 'verbose';
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
  final databaseService = Utils.isRedisUsed ? RedisDatabaseService() : HiveDatabaseService(Utils.appCacheDirectory);
  await databaseService.init();

  /// let's initiate the build
  final buildCache = cached_build_runner.CachedBuildRunner(databaseService);
  await buildCache.build();
}

void _parseArgs(List<String> args) {
  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Print out usage instructions.', negatable: false)
    ..addFlag(verbose, abbr: 'v', help: 'Prints out logs during build_runner build.', negatable: false)
    ..addFlag(
      generateTestMocks,
      abbr: 't',
      help: 'Generates mocks for test files, if this flag is not provided mock generations are skipped.',
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
      help: 'Mandatory: Provide the directory where this tool can keep the caches.',
    )
    ..addOption(projectDirectory, abbr: 'p', help: 'Mandatory: Provide the directory of the project.');

  final result = parser.parse(args);

  if (result.wasParsed(help)) {
    Logger.log('''
cached_build_runner: Optimizes the build_runner by caching generated codes for non changed .dart files.

${parser.usage}
''');
    exit(0);
  }

  if (result.wasParsed(cacheDirectory)) {
    Utils.appCacheDirectory = result[cacheDirectory];
  } else {
    Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
    Logger.log("As no '$cacheDirectory' was specified, using the default directory: ${Utils.appCacheDirectory}");
  }

  if (result.wasParsed(projectDirectory)) {
    Utils.projectDirectory = result[projectDirectory];
  } else {
    Utils.projectDirectory = Utils.getDefaultProjectDirectory();
    Logger.log("As no '$projectDirectory' was specified, using the current directory.");
  }

  Utils.isVerbose = result.wasParsed(verbose);
  Utils.generateTestMocks = result.wasParsed(generateTestMocks);
  Utils.isRedisUsed = result.wasParsed(useRedis);
}
