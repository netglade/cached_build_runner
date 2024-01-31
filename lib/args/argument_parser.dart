import 'package:args/args.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';

class ArgumentParser {
  final ArgParser _argParser;

  ArgumentParser(this._argParser) {
    _addFlagAndOption();
  }

  void parseArgs(Iterable<String>? arguments) {
    if (arguments == null) return;

    /// parse all args
    final result = _argParser.parse(arguments);

    /// cache directory
    if (result.wasParsed(ArgsUtils.cacheDirectory)) {
      Utils.appCacheDirectory = result[ArgsUtils.cacheDirectory] as String;
    } else {
      Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
      Logger.i(
        "As no '${ArgsUtils.cacheDirectory}' was specified, using the default directory: ${Utils.appCacheDirectory}",
      );
    }

    /// verbose
    Utils.isVerbose = result[ArgsUtils.verbose] as bool;
    Utils.isDebug = result[ArgsUtils.debug] as bool;

    // enable prunning
    Utils.isPruneEnabled = result[ArgsUtils.lockPrune] as bool;
  }

  void _addFlagAndOption() {
    _argParser
      ..addFlag(
        ArgsUtils.verbose,
        abbr: 'v',
        help: 'Enables verbose mode',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.debug,
        abbr: 'd',
        help: 'Enables debug mode',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.lockPrune,
        abbr: 'p',
        help: 'Enable pruning cache directory when pubspec.lock was changed since last build.',
        defaultsTo: true,
      )
      ..addSeparator('')
      ..addOption(
        ArgsUtils.cacheDirectory,
        abbr: 'c',
        help: 'Provide the directory where this tool can keep the caches.',
      );
  }
}
