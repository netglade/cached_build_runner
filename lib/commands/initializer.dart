import 'dart:io';

import 'package:cached_build_runner/utils/utils.dart';

/// This class configures the CachedBuildRunner as per the arguments parsed.
/// And also initializes any variables, or create cache directory if non-existing.
class Initializer {
  const Initializer();
  void init() {
    // the project directory is always where the `flutter run` command is executed
    // which is the current directory
    Utils.projectDirectory = Platform.environment['CACHED_BUILD_RUNNER_PROJECT_DIRECTORY'] ?? Directory.current.path;

    // let's make the appCacheDirectory if not existing already
    Directory(Utils.appCacheDirectory).createSync(recursive: true);

    // init package name of project
    Utils.initAppPackageName();
  }
}
