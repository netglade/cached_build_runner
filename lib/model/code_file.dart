class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;
  final String? suffix;

  const CodeFile({
    required this.path,
    required this.digest,
    required this.suffix,
    this.isTestFile = false,
  });

  String getGeneratedFilePath() {
    final lastDotDart = path.lastIndexOf('.dart');

    if (lastDotDart >= 0) {
      final fileExtension = isTestFile ? '.mocks.dart' : '.${suffix ?? 'g'}.dart';

      // ignore: avoid-substring, should be ok.
      return '${path.substring(0, lastDotDart)}$fileExtension';
    }

    return path;
  }

  @override
  String toString() {
    return '($path, $digest, $isTestFile, Suffix: ${suffix ?? 'null'})';
  }
}
