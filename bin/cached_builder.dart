import 'dart:io';

import 'package:args/args.dart';
import 'package:cached_builder/cached_builder.dart' as build_cache;
import 'package:cached_builder/database/database_service.dart';
import 'package:cached_builder/utils/log.dart';
import 'package:cached_builder/utils/utils.dart';

/// parser argument flags & options
const help = 'help';
const verbose = 'verbose';
const skipTest = 'skip-test';
const cacheDirectory = 'cache-directory';
const projectDirectory = 'project-directory';

Future<void> main(List<String> arguments) async {
  final startTime = DateTime.now();

  /// initialize parser - read necessary options
  _initParser(arguments);

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

void _initParser(List<String> args) {
  final parser = ArgParser()
    ..addFlag(help, abbr: 'h', help: 'Print out usage instructions.', negatable: false)
    ..addFlag(verbose, abbr: 'v', help: 'Prints out logs during build_runner build', negatable: false)
    ..addFlag(skipTest, abbr: 's', help: 'Skips running build_runner build for "test" directory', negatable: false)
    ..addSeparator('')
    ..addOption(cacheDirectory, abbr: 'c', help: 'Provide the directory where this tool can keep the caches.')
    ..addOption(projectDirectory, abbr: 'p', help: 'Provide the directory of the project');

  final result = parser.parse(args);

  if (result.wasParsed(help)) {
    Logger.log('''
cached_build_runner: Helps to optimize the build_runner by caching generated codes for non changed .dart files

${parser.usage}}
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
  Utils.skipsTest = result.wasParsed(skipTest);
}
