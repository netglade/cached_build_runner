import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/args/build_and_watch_argument_parser.dart';
import 'package:cached_build_runner/cached_build_runner.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import 'package:get_it/get_it.dart';

class BuildCommand extends Command<void> {
  late final BuildAndWatchArgumentParser _argumentParser;
  final Initializer _initializer;
  final CachedBuildRunner _cachedBuildRunner;

  @override
  String get description => 'Performs a single build on the specified targets and then exits.';

  @override
  String get name => ArgsUtils.commands.build;

  BuildCommand({CachedBuildRunner? cachedBuildRunner})
      : _initializer = const Initializer(),
        _cachedBuildRunner = cachedBuildRunner ?? GetIt.I<CachedBuildRunner>() {
    _argumentParser = BuildAndWatchArgumentParser(argParser);
  }

  @override
  Future<void> run() {
    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    _initializer.init();

    return _cachedBuildRunner.build();
  }
}
