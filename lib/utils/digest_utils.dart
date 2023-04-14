import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../core/dependency_visitor.dart';

abstract class DigestUtils {
  /// Calculates the MD5 digest of a given string [string].
  static String generateDigestForRawString(String string) {
    return md5.convert(utf8.encode(string)).toString();
  }

  /// Calculates the MD5 digest of a given file [filePath].
  static String generateDigestForSingleFile(String filePath) {
    return md5.convert(File(filePath).readAsBytesSync()).toString();
  }

  /// Calculates the MD5 digest of multiple files [filePaths].
  static String generateDigestForMultipleFile(List<String> filePaths) {
    if (filePaths.isEmpty) {
      throw Exception(
        'filePaths list must not be empty when invoked to generate digest',
      );
    }

    final sb = StringBuffer();

    for (final file in filePaths) {
      sb.write(generateDigestForSingleFile(file));
      sb.write('-');
    }

    return generateDigestForRawString(sb.toString());
  }

  /// Calculates a MD5 digest of a given class file, considering it's dependencies as well
  static String generateDigestForClassFile(
    DependencyVisitor visitor,
    String filePath,
  ) {
    final dependencies = visitor.getDependenciesPath(filePath);
    return generateDigestForMultipleFile([filePath, ...dependencies]);
  }

  /// Calculates a combined digest for the provided [filePaths] list.
  static String generateDigestForMultipleClassFile(
    DependencyVisitor visitor,
    List<String> filePaths,
  ) {
    if (filePaths.isEmpty) {
      throw Exception(
        'filePaths list must not be empty when invoked to generate digest',
      );
    }

    final sb = StringBuffer();

    for (final file in filePaths) {
      sb.write(generateDigestForClassFile(visitor, file));
      sb.write('-');
    }

    return generateDigestForRawString(sb.toString());
  }
}
