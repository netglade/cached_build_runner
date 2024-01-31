import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/commands/cache/cache_prune_sub_command.dart';
import 'package:cached_build_runner/commands/cache/list_cache_sub_command.dart';

class CacheCommand extends Command<void> {
  @override
  String get description => 'Prune cache directory';

  @override
  String get name => ArgsUtils.commands.cache;

  CacheCommand() {
    addSubcommand(CachePruneSubCommand());
    addSubcommand(ListCacheSubCommand());
  }

  // @override
  // Future<void> run() {
  //   DiContainer.setup();

  //   /// parse args for the command
  //   _argumentParser.parseArgs(argResults?.arguments);

  //   /// let's get the cachedBuildRunner and execute the build
  //   final cachedBuildRunner = _initializer.init();

  //   return cachedBuildRunner.prune();
  // }
}
