import 'dart:io';

import 'package:crypto/crypto.dart';

import 'log.dart';

abstract class Utils {
  static String appCacheDirectory = '/Users/jyotirmoypaul/.build_cache';
  static String projectDirectory = '/Users/jyotirmoypaul/Documents/workspace/uni-app';

  static String calculateDigestFor(String filePath) {
    return md5.convert(File(filePath).readAsBytesSync()).toString();
  }

  static void logHeader(String title) {
    Logger.log('---------------------- $title ----------------------');
  }
}
