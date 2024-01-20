import 'dart:io';

extension DirectoryExtn on Directory {
  Stream<FileSystemEvent> watchDartSourceCodeFiles() {
    return watch(recursive: true).where(
      (e) => e.path.endsWith('.dart') && !e.path.endsWith('.g.dart') && !e.path.endsWith('.mocks.dart'),
    );
  }
}

extension FileExtn on File {
  bool isDartSourceCodeFile() {
    return path.endsWith('.dart') && r'.+\..+\.dart'.allMatches(path).isEmpty;
    //  !path.endsWith('.g.dart') && !path.endsWith('.mocks.dart');
  }
}
