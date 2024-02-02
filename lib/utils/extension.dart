// ignore_for_file: prefer-match-file-name

import 'dart:io';

import 'package:cached_build_runner/utils/constants.dart';

extension DirectoryExtn on Directory {
  Stream<FileSystemEvent> watchDartSourceCodeFiles() {
    return watch(recursive: true).where(
      (e) => e.path.endsWith('.dart') && Constants.partFileExtensionRegex.allMatches(e.path).isEmpty,
    );
  }
}

extension FileExtn on File {
  bool isDartSourceCodeFile() {
    final matches = Constants.partFileExtensionRegex.allMatches(path);

    return path.endsWith('.dart') && matches.isEmpty;
  }
}
