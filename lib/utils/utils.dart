import 'dart:io';

import 'package:crypto/crypto.dart';

import 'log.dart';

abstract class Utils {
  static String appCacheDirectory = '';
  static String projectDirectory = '';
  static bool isVerbose = true;
  static bool skipsTest = false;

  static String calculateDigestFor(String filePath) {
    return md5.convert(File(filePath).readAsBytesSync()).toString();
  }

  static void logHeader(String title) {
    Logger.log('\n---------------------- $title ----------------------');
  }
}
