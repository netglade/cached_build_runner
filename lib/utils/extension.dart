import 'dart:io';

import 'package:cached_build_runner/utils/constants.dart';

extension DirectoryExtn on Directory {
  Stream<FileSystemEvent> watchDartSourceCodeFiles() {
    return watch(recursive: true).where(
      (e) => e.path.endsWith('.dart') && Constants.generatedPartFileRegex.allMatches(e.path).isEmpty,
    );
  }
}

extension FileExtn on File {
  bool isDartSourceCodeFile() {
    final matches = Constants.generatedPartFileRegex.allMatches(path);

    //print('Path $path matches: $matches. Return ${path.endsWith('.dart') && matches.isEmpty}');
    return path.endsWith('.dart') && matches.isEmpty;
    //  !path.endsWith('.g.dart') && !path.endsWith('.mocks.dart');
  }
}
