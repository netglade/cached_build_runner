import 'package:cached_build_runner/model/code_file_generated_type.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:path/path.dart' as path_utils;

class CodeFile {
  final String path;
  final String digest;
  final bool isTestFile;
  final String? suffix;
  final CodeFileGeneratedType generatedType;

  const CodeFile({
    required this.path,
    required this.digest,
    required this.suffix,
    required this.generatedType,
    this.isTestFile = false,
  });

  String getGeneratedFilePath() {
    final lastDotDart = path.lastIndexOf('.dart');

    final fileExtension = '.${suffix ?? 'g'}.dart';
    // ignore: avoid-substring, should be ok.
    final subPath = '${path.substring(0, lastDotDart)}$fileExtension';

    return path_utils.relative(subPath, from: Utils.projectDirectory);
  }

  @override
  String toString() {
    return '($path, $digest, $isTestFile, Suffix: ${suffix ?? 'null'})';
  }
}
