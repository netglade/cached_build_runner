import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/args/cache_argument_parser.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import 'package:cached_build_runner/core/cache_provider.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:get_it/get_it.dart';

class CachePruneSubCommand extends Command<void> {
  late final CacheArgumentParser _argumentParser;
  final Initializer _initializer;
  final CacheProvider _cacheProvider;

  @override
  String get description => 'Prune cache directory';

  @override
  String get name => ArgsUtils.commands.prune;

  @override
  bool get takesArguments => true;

  CachePruneSubCommand({CacheProvider? cacheProvider})
      : _cacheProvider = cacheProvider ?? GetIt.I<CacheProvider>(),
        _initializer = const Initializer() {
    _argumentParser = CacheArgumentParser(argParser);
  }

  @override
  Future<void> run() async {
    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    _initializer.init();

    Logger.i('Clearing cache...');
    await _cacheProvider.prune();

    Logger.i('Done');
  }
}
