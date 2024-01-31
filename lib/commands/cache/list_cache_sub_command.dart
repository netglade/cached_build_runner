import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/args/cache_argument_parser.dart';
import 'package:cached_build_runner/cached_build_runner.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import 'package:cached_build_runner/core/cache_provider.dart';
import 'package:get_it/get_it.dart';

class ListCacheSubCommand extends Command<void> {
  late final CacheArgumentParser _argumentParser;
  final Initializer _initializer;
  final CacheProvider _cacheProvider;
  final CachedBuildRunner _runner;

  @override
  String get description => 'Prune cache directory';

  @override
  String get name => ArgsUtils.commands.list;

  @override
  bool get takesArguments => true;

  ListCacheSubCommand({
    CacheProvider? cacheProvider,
    CachedBuildRunner? cachedBuildRunner,
  })  : _cacheProvider = cacheProvider ?? GetIt.I<CacheProvider>(),
        _runner = cachedBuildRunner ?? GetIt.I<CachedBuildRunner>(),
        _initializer = const Initializer() {
    _argumentParser = CacheArgumentParser(argParser);
  }

  @override
  Future<void> run() async {
    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    _initializer.init();

    await _runner.listAllCachedFiles();
  }
}
