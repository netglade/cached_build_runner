import 'dart:io';

import 'package:path/path.dart' as path;

import 'log.dart';

/// A utility class that provides helper methods for various operations.
abstract class Utils {
  static String appPackageName = '';
  static String appCacheDirectory = '';
  static String projectDirectory = '';
  static bool isVerbose = true;
  static bool isRedisUsed = false;
  static bool isPruneEnabled = false;

  /// Initializes the app package name by reading it from pubspec.yaml.
  static void initAppPackageName() {
    const pubspecFileName = 'pubspec.yaml';
    const searchString = 'name:';

    final pubspecFile = File(path.join(
      Utils.projectDirectory,
      pubspecFileName,
    ));

    if (!pubspecFile.existsSync()) {
      reportError(
        'Could not find $pubspecFileName in project directory: ${Utils.projectDirectory}',
      );
    }

    for (final line in pubspecFile.readAsLinesSync()) {
      if (line.contains(searchString)) {
        appPackageName = line.split(searchString).last.trim();
      }
    }
  }

  /// Logs a header [title] to the console.
  static void logHeader(String title) {
    Logger.i(title);
  }

  /// Retrieves the file name from the given [path].
  static String getFileName(String path) {
    return path.split('/').last;
  }

  /// Delays the execution for 500 milliseconds.
  static Future<void> delay500ms() {
    return Future.delayed(const Duration(milliseconds: 500));
  }

  /// Returns the default cache directory based on the user's platform.
  static String getDefaultCacheDirectory() {
    const defaultCacheDirectoryName = '.cached_build_runner';
    String homeDir;

    if (Platform.isWindows) {
      homeDir = Platform.environment['USERPROFILE'] ?? '';
    } else {
      homeDir = Platform.environment['HOME'] ?? '';
    }

    if (homeDir.isEmpty) {
      reportError(
        'Could not set default cache directory. Please use the --cache-directory flag to provide a cache directory.',
      );
    }

    return path.join(path.normalize(homeDir), defaultCacheDirectoryName);
  }

  static void reportError(String message) {
    Logger.e(message);
    exit(1);
  }
}
