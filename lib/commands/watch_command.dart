import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_parser.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import 'package:cached_build_runner/di_container.dart';

class WatchCommand extends Command<void> {
  late final ArgumentParser _argumentParser;
  final Initializer _initializer;

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and rebuilding as appropriate.';

  @override
  String get name => ArgsUtils.watch;

  WatchCommand() : _initializer = const Initializer() {
    _argumentParser = ArgumentParser(argParser);
  }

  @override
  Future<void> run() {
    DiContainer.setup();

    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    final cachedBuildRunner = _initializer.init();

    return cachedBuildRunner.watch();
  }
}
