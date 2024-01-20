class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;
  final String? suffix;

  CodeFile({
    required this.path,
    required this.digest,
    this.isTestFile = false,
    required this.suffix,
  });

  @override
  String toString() {
    return '($path, $digest, $isTestFile, $suffix)';
  }
}
