import 'dart:io';

extension DirectoryExtn on Directory {
  Stream<FileSystemEvent> watchDartSourceCodeFiles() {
    return watch(recursive: true).where(
      (e) =>
          e.path.endsWith('.dart') &&
          !e.path.endsWith('.g.dart') &&
          !e.path.endsWith('.chopper.dart') &&
          !e.path.endsWith('.freezed.dart') &&
          !e.path.endsWith('.mocks.dart'),
    );
  }
}

extension FileExtn on File {
  bool isDartSourceCodeFile() {
    return path.endsWith('.dart') &&
        !path.endsWith('.g.dart') &&
        !path.endsWith('.chopper.dart') &&
        !path.endsWith('.freezed.dart') &&
        !path.endsWith('.mocks.dart');
  }
}
