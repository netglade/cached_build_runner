class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;

  CodeFile({
    required this.path,
    required this.digest,
    this.isTestFile = false,
  });

  @override
  String toString() {
    return '($path, $digest, $isTestFile)';
  }
}
