import 'package:args/command_runner.dart';
import 'package:cached_build_runner/commands/build_command.dart';
import 'package:cached_build_runner/commands/watch_command.dart';

Future<void> main(List<String> arguments) async {
  const commandName = 'cached_build_runner';
  const commandDescription =
      'Optimizes the build_runner by caching generated codes for non changed .dart files';

  final runner = CommandRunner(commandName, commandDescription)
    ..addCommand(BuildCommand())
    ..addCommand(WatchCommand());

  runner.run(arguments);
}
