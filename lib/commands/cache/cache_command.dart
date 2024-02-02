import 'package:args/command_runner.dart';
import 'package:cached_build_runner/args/args_utils.dart';
import 'package:cached_build_runner/commands/cache/cache_prune_sub_command.dart';
import 'package:cached_build_runner/commands/cache/list_cache_sub_command.dart';

class CacheCommand extends Command<void> {
  @override
  String get description => 'Commands for inspecting and manipulating cache directory';

  @override
  String get name => ArgsUtils.commands.cache;

  CacheCommand() {
    addSubcommand(CachePruneSubCommand());
    addSubcommand(ListCacheSubCommand());
  }
}
