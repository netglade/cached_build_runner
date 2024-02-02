import 'package:args/args.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/args/argument_parser_base.dart';
import 'package:cached_build_runner/utils/utils.dart';

class CacheArgumentParser extends ArgumentParserBase {
  final ArgParser _argParser;

  CacheArgumentParser(this._argParser) {
    _addFlagAndOption();
  }

  void parseArgs(Iterable<String>? arguments) {
    if (arguments == null) return;

    final result = _argParser.parse(arguments);

    // cache directory
    parseCacheDirectory(result);

    // verbose
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
