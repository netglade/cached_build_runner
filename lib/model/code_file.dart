class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;
  final String generatedSuffix;

  CodeFile({
    required this.path,
    required this.digest,
    this.generatedSuffix = '.g.dart',
    this.isTestFile = false,
  });

  @override
  String toString() {
    return '($path, $digest, $isTestFile, $generatedSuffix)';
  }
}
