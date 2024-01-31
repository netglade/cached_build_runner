import 'package:args/args.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';

class BuildAndWatchArgumentParser {
  final ArgParser _argParser;

  BuildAndWatchArgumentParser(this._argParser) {
    _addFlagAndOption();
  }

  void parseArgs(Iterable<String>? arguments) {
    if (arguments == null) return;

    /// parse all args
    final result = _argParser.parse(arguments);

    /// cache directory
    if (result.wasParsed(ArgsUtils.args.cacheDirectory)) {
      Utils.appCacheDirectory = result[ArgsUtils.args.cacheDirectory] as String;
    } else {
      Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
      Logger.i(
        "As no '${ArgsUtils.args.cacheDirectory}' was specified, using the default directory: ${Utils.appCacheDirectory}",
      );
    }

    /// verbose
    Utils.isVerbose = result[ArgsUtils.args.verbose] as bool;
    Utils.isDebug = result[ArgsUtils.args.debug] as bool;

    // enable prunning
    Utils.isPruneEnabled = result[ArgsUtils.args.lockPrune] as bool;
  }

  void _addFlagAndOption() {
    _argParser
      ..addFlag(
        ArgsUtils.args.verbose,
        abbr: 'v',
        help: 'Enables verbose mode',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.args.debug,
        abbr: 'd',
        help: 'Enables debug mode',
        negatable: false,
      )
      ..addFlag(
        ArgsUtils.args.lockPrune,
        abbr: 'p',
        help: 'Enable pruning cache directory when pubspec.lock was changed since last build.',
        defaultsTo: true,
      )
      ..addSeparator('')
      ..addOption(
        ArgsUtils.args.cacheDirectory,
        abbr: 'c',
        help: 'Provide the directory where this tool can keep the caches.',
      );
  }
}
