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

  static List<String> _filesToSearchIn(String originFile) {
    final searchString = 'package:$appPackageName/';
    final content = File(originFile).readAsLinesSync();

    final paths = <String>[];

    for (final line in content) {
      if (line.contains(searchString)) {
        final i = line.indexOf(searchString) + searchString.length;
        final dependency = line.substring(i, line.length - 2);
        paths.add(path.join(Utils.projectDirectory, 'lib', dependency));
      }
    }

    return paths;
  }

  static String calculateTestFileDigestFor(List<String> dependencies) {
    assert(dependencies.isNotEmpty);

    final originFile = dependencies[0];
    List<String> dependentFilePaths = [originFile];

    for (final dependency in dependencies.sublist(1)) {
      if (dependency.trim().isEmpty) continue;
      final process = Process.runSync(
        'grep',
        [
          '-rl',
          '-w',
          'class ${dependency.trim()}',
          ..._filesToSearchIn(originFile),
        ],
      );

      if (process.stderr.toString().isNotEmpty) {
        throw Exception('Utils.calculateTestFileDigestFor :: failed to run grep :: ${process.stderr}');
      }

      final filePath = process.stdout.toString().trim();
      if (filePath.isNotEmpty) {
        dependentFilePaths.add(filePath);
      } else {
        /// file is not present in our repo, but is from an external package
        dependentFilePaths.add(dependency.trim());
      }
    }

    final sb = StringBuffer();

    for (final file in dependentFilePaths) {
      /// an file exist check is needed because we may be depending on external packages
      /// which needs mock generations, now those files doesn't exists in our repo,
      /// but we need to make sure they needs to be generated
      if (File(file).existsSync()) {
        sb.write(calculateDigestFor(file));
      } else {
        sb.write(calculateDigestForString(file));
      }

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
