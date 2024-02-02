import 'package:args/args.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:meta/meta.dart';

abstract class ArgumentParserBase {
  @protected
  void parseCacheDirectory(ArgResults result) {
    if (result.wasParsed(ArgsUtils.args.cacheDirectory)) {
      Utils.appCacheDirectory = result[ArgsUtils.args.cacheDirectory] as String;
      Logger.i('Using "${Utils.appCacheDirectory}" as cache directory');
    } else {
      Utils.appCacheDirectory = Utils.getDefaultCacheDirectory();
      Logger.i(
        "As no '${ArgsUtils.args.cacheDirectory}' was specified, using the default directory: ${Utils.appCacheDirectory}",
      );
    }
  }
}
