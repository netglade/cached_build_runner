import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cached_build_runner/commands/initializer.dart';
import '../args/args_parser.dart';
import '../args/args_utils.dart';

class BuildCommand extends Command {
  late final ArgumentParser _argumentParser;
  final Initializer _initializer;

  BuildCommand() : _initializer = Initializer() {
    _argumentParser = ArgumentParser(argParser);
  }

  @override
  String get description =>
      'Performs a single build on the specified targets and then exits.';

  @override
  String get name => ArgsUtils.build;

  @override
  FutureOr? run() async {
    /// parse args for the command
    _argumentParser.parseArgs(argResults?.arguments);

    /// let's get the cachedBuildRunner and execute the build
    final cachedBuildRunner = await _initializer.init();
    return cachedBuildRunner.build();
  }
}
