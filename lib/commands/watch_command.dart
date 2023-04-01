import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import '../args/args_utils.dart';

import '../args/args_parser.dart';

class WatchCommand extends Command {
  late final ArgumentParser _argumentParser;
  final Initializer _initializer;

  WatchCommand() : _initializer = Initializer() {
    _argumentParser = ArgumentParser(argParser);
  }

  @override
  String get description =>
      'Builds the specified targets, watching the file system for updates and rebuilding as appropriate.';

  @override
  String get name => ArgsUtils.watch;

  @override
  FutureOr? run() async {
    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    final cachedBuildRunner = await _initializer.init();
    return cachedBuildRunner.watch();
  }
}
