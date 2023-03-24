import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'log.dart';

abstract class Utils {
  static String appPackageName = '';
  static String appCacheDirectory = '';
  static String projectDirectory = '';
  static bool isVerbose = true;
  static bool generateTestMocks = false;
  static bool isRedisUsed = false;

  static void initAppPackageName() {
    const pubspecFileName = 'pubspec.yaml';
    const searchString = 'name:';

    final pubspecFile = File(path.join(Utils.projectDirectory, pubspecFileName));
    for (final line in pubspecFile.readAsLinesSync()) {
      if (line.contains(searchString)) {
        appPackageName = line.split(searchString).last.trim();
      }
    }
  }

  static String calculateDigestForString(String value) {
    return md5.convert(utf8.encode(value)).toString();
  }

  static final Map<String, String> _hashMap = {};

  static String calculateDigestFor(String filePath) {
    if (_hashMap.containsKey(filePath)) {
      _hashMap[filePath]!;
    }

    final hash = md5.convert(File(filePath).readAsBytesSync()).toString();
    return _hashMap[filePath] = hash;
  }

  static String getFilePathFromImportLine(String importLine) {
    final searchString = 'package:$appPackageName/';

    final fromIndex = importLine.indexOf(searchString) + searchString.length;
    int toIndex = importLine.lastIndexOf("'");
    if (toIndex == -1) toIndex = importLine.lastIndexOf('"');

    final dependency = importLine.substring(fromIndex, toIndex);
    return path.join(Utils.projectDirectory, 'lib', dependency).trim();
  }

  static String calculateTestFileDigestFor(List<String> dependencies) {
    if (dependencies.isEmpty) {
      throw Exception('Dependencies list cannot be empty when invoked to generate digest');
    }

    final sb = StringBuffer();

    for (final file in dependencies) {
      sb.write(calculateDigestFor(file));
      sb.write('-');
    }

    return calculateDigestForString(sb.toString());
  }

  static void logHeader(String title) {
    Logger.i(title);
  }

  static String getFileName(String path) {
    return path.split('/').last;
  }

  static Future<void> delay500ms() {
    return Future.delayed(const Duration(milliseconds: 500));
  }

  static String getDefaultCacheDirectory() {
    const defaultCacheDirectoryName = '.cached_build_runner';
    String homeDir;

    if (Platform.isWindows) {
      homeDir = Platform.environment['USERPROFILE'] ?? '';
    } else {
      homeDir = Platform.environment['HOME'] ?? '';
    }

    if (homeDir.isEmpty) {
      throw Exception(
        'Could not set default cache directory. Please use the --cache-directory flag to provide a cache directory.',
      );
    }

    return path.join(path.normalize(homeDir), defaultCacheDirectoryName);
  }

  /// default project directory is the current directory
  static String getDefaultProjectDirectory() {
    return Directory.current.path;
  }
}
