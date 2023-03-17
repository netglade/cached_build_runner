import 'dart:io';

import 'package:args/args.dart';
import 'package:cached_builder/cached_builder.dart' as build_cache;
import 'package:cached_builder/database/database_service.dart';
import 'package:cached_builder/utils/log.dart';
import 'package:cached_builder/utils/utils.dart';

/// parser argument flags & options
const help = 'help';
const verbose = 'verbose';
const useRedis = 'redis';
const generateTestMocks = 'generate-test-mock';
const cacheDirectory = 'cache-directory';
const projectDirectory = 'project-directory';

Future<void> main(List<String> arguments) async {
  final startTime = DateTime.now();

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
  final buildCache = build_cache.BuildCache(databaseService);
  await buildCache.build();

  final timeTook = DateTime.now().difference(startTime);
  Utils.logHeader('Code Generation took: $timeTook');
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
    Logger.log('Please provide a cache directory for the tool. Check -h or --help for more details.');
    exit(0);
  }

  if (result.wasParsed(projectDirectory)) {
    Utils.projectDirectory = result[projectDirectory];
  } else {
    Logger.log('Please provide a project directory. Check -h or --help for more details.');
    exit(0);
  }

  Utils.isVerbose = result.wasParsed(verbose);
  Utils.generateTestMocks = result.wasParsed(generateTestMocks);
  Utils.isRedisUsed = result.wasParsed(useRedis);
}
