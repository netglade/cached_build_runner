abstract class ArgsUtils {
  static const commands = _Commands();
  static const args = _Args();
}

class _Commands {
  String get watch => 'watch';
  String get build => 'build';
  String get cache => 'cache';

  // Cache subcomammnds
  String get prune => 'prune';
  String get list => 'list';

  const _Commands();
}

class _Args {
  String get verbose => 'verbose';
  String get debug => 'debug';
  String get cacheDirectory => 'cache-directory';
  String get lockPrune => 'prune';
  String get clear => 'clear';

  const _Args();
}
