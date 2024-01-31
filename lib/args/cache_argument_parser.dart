import 'package:args/args.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';

class CacheArgumentParser {
  final ArgParser _argParser;

  CacheArgumentParser(this._argParser) {
    _addFlagAndOption();
  }

  void parseArgs(Iterable<String>? arguments) {
    if (arguments == null) return;

    /// parse all args
    final result = _argParser.parse(arguments);

    /// cache directory
    if (result.wasParsed(ArgsUtils.args.cacheDirectory)) {
      Utils.appCacheDirectory = result[ArgsUtils.args.cacheDirectory] as String;
      Logger.i('Using "${Utils.appCacheDirectory}" as cache directory');
    } else {
      Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
      Logger.i(
        "As no '${ArgsUtils.args.cacheDirectory}' was specified, using the default directory: ${Utils.appCacheDirectory}",
      );
    }

    /// verbose
    Utils.isVerbose = result[ArgsUtils.args.verbose] as bool;
  }

  void _addFlagAndOption() {
    _argParser
      ..addFlag(
        ArgsUtils.args.verbose,
        abbr: 'v',
        help: 'Enables verbose mode',
        negatable: false,
      )
      ..addOption(
        ArgsUtils.args.cacheDirectory,
        abbr: 'c',
        help: 'Provide the directory where this tool can keep the caches.',
      );
  }
}
