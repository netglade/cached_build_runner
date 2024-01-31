import 'package:cached_build_runner/utils/utils.dart';
import 'package:path/path.dart' as pathUtils;

enum CodeFileGeneratedType {
  import,
  partFile,
}

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
    final subPath = '${path.substring(0, lastDotDart)}$fileExtension';

    return pathUtils.relative(subPath, from: Utils.projectDirectory);
  }

  String getSourceFilePath() {
    return getGeneratedFilePath();

    //if (generatedType == CodeFileGeneratedType.import) return getGeneratedFilePath();

    //return pathUtils.relative(path, from: Utils.projectDirectory);
  }

  @override
  String toString() {
    return '($path, $digest, $isTestFile, Suffix: ${suffix ?? 'null'})';
  }
}
