class CodeFile {
  final String path;
  final String digest;

  CodeFile({
    required this.path,
    required this.digest,
  });

  @override
  String toString() {
    return '$path: $digest';
  }
}
