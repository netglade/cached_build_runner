import 'dart:io';

import 'package:cached_build_runner/core/dependency_visitor.dart';
import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/digest_utils.dart';
import 'package:cached_build_runner/utils/extension.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as path;

typedef CodeFileBuild = ({String path, String? suffix, CodeFileGeneratedType type});

class FileParser {
  final DependencyVisitor _dependencyVisitor;

  FileParser({DependencyVisitor? dependencyVisitor})
      : _dependencyVisitor = dependencyVisitor ?? GetIt.I<DependencyVisitor>();

  /// This method returns all the files in the 'lib/' directory that need code generation. It first identifies the files
  /// containing part '.g.dart'; statements using a regular expression. It then uses the grep command to find those
  /// files and exclude any files that already have a .g.dart extension. Finally, it maps the file paths to a list of
  /// CodeFile instances, which contains the file path and its corresponding digest calculated using the Utils.calculateDigestFor
  /// method.
  ///
  /// Returns a list of [CodeFile] instances that represent the files that need code generation.
  List<CodeFile> fetchFilePathsFromLib() {
    /// Files in "lib/" that needs code generation
    final libDirectory = Directory(path.join(Utils.projectDirectory, 'lib'));

    final libPathList = <CodeFileBuild>[];

    final libFiles = libDirectory.listSync(
      recursive: true,
      followLinks: false,
    );

    for (final entity in libFiles) {
      if (entity is! File || !entity.isDartSourceCodeFile()) continue;

      final result = _parseFile(entity);

      if (result != null) libPathList.add(result);
    }

    Logger.i(
      'Found ${libPathList.length} files in "lib/" that supports code generation',
    );

    return libPathList
        .map<CodeFile>(
          (f) => CodeFile(
            path: f.path,
            digest: DigestUtils.generateDigestForClassFile(
              _dependencyVisitor,
              f.path,
            ),
            suffix: f.suffix,
            generatedType: f.type,
          ),
        )
        .toList();
  }

  CodeFileBuild? _parseFile(File entity) {
    final filePath = entity.path.trim();
    final fileContent = entity.readAsStringSync();

    final partMatch = Constants.partFileRegex.firstMatch(fileContent);

    if (partMatch != null) {
      print('part file: $filePath');

      return (path: filePath, suffix: partMatch.group(1), type: CodeFileGeneratedType.partFile);
    }

    final importMatch = Constants.generatedFileImportRegExp.firstMatch(fileContent);

    if (importMatch != null) {
      print('import file: $filePath');
      print(importMatch.pattern);

      return (path: filePath, suffix: importMatch.group(1), type: CodeFileGeneratedType.import);
    }

    final partOfMatch = Constants.partOfFileRegex.firstMatch(fileContent);

    if (partOfMatch != null) {
      final partOf = partOfMatch.group(1)!;

      final f = path.normalize(path.join(entity.parent.path, partOf));
      print('Result: $f');

      final absolute = path.join(Utils.projectDirectory, partOf);
      final normalized = path.normalize(absolute);
      print('partOf: $partOf, abs: $absolute, norm: $normalized');
      // final result = checkPartOfFile(filePath, normalized);

      return _parseFile(File(normalized));
    }

    return null;
  }

  // CodeFileBuild? checkPartOfFile(String path) {
  //   final file = File(path);
  //   final fileContent = file
  // }
}
