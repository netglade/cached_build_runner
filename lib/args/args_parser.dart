import 'package:args/args.dart';

import '../utils/log.dart';
import '../utils/utils.dart';
import 'args_utils.dart';

class ArgumentParser {
  final ArgParser _argParser;

  ArgumentParser(this._argParser) {
    _addFlagAndOption();
  }

  ArgParser _addFlagAndOption() {
    return _argParser
      ..addFlag(
        ArgsUtils.quiet,
        abbr: 'q',
        help: 'Disables printing out logs during build.',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.useRedis,
        abbr: 'r',
        help:
            'Use redis database, if installed on the system. Using redis allows multiple instance access. Ideal for usage in pipelines. Default implementation uses a file system storage (hive), which is idea for usage in local systems.',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.prune,
        abbr: 'p',
        help: 'Enable pruning cache directory when pubspec.lock was changed since last build.',
        negatable: true,
        defaultsTo: true,
      )
      ..addSeparator('')
      ..addOption(
        ArgsUtils.cacheDirectory,
        abbr: 'c',
        help: 'Provide the directory where this tool can keep the caches.',
      );
  }

  void parseArgs(Iterable<String>? arguments) {
    if (arguments == null) return;

    /// parse all args
    final result = _argParser.parse(arguments);

    /// cache directory
    if (result.wasParsed(ArgsUtils.cacheDirectory)) {
      Utils.appCacheDirectory = result[ArgsUtils.cacheDirectory];
    } else {
      Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
      Logger.i(
        "As no '${ArgsUtils.cacheDirectory}' was specified, using the default directory: ${Utils.appCacheDirectory}",
      );
    }

    /// quiet
    Utils.isVerbose = !result.wasParsed(ArgsUtils.quiet);

    /// use redis
    Utils.isRedisUsed = result.wasParsed(ArgsUtils.useRedis);

    // enable prunning
    Utils.isPruneEnabled = result[ArgsUtils.prune];
  }
}
