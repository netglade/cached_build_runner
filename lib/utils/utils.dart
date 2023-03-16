import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'log.dart';

abstract class Utils {
  static String appCacheDirectory = '';
  static String projectDirectory = '';
  static bool isVerbose = true;
  static bool generateTestMocks = false;
  static bool isRedisUsed = false;

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

  static String calculateTestFileDigestFor(List<String> dependencies) {
    assert(dependencies.isNotEmpty);

    List<String> dependentFilePaths = [dependencies[0]];

    for (final dependency in dependencies.sublist(1)) {
      if (dependency.trim().isEmpty) continue;
      final process = Process.runSync(
        'grep',
        [
          '-rl',
          '-m',
          '1',
          '-w',
          'class ${dependency.trim()}',
          path.join(Utils.projectDirectory, 'lib'),
        ],
      );

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
    Logger.log('\n---------------------- $title ----------------------', fatal: true);
  }

  static String getFileName(String path) {
    return path.split('/').last;
  }
}
