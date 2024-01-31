import 'dart:io';

import 'package:cached_build_runner/utils/constants.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';
import 'package:path/path.dart' as path;

/// Used for calculating hash.
class DependencyVisitor {
  static const _relativeImportsConst = 'relative-imports';
  static const _absoluteImportsConst = 'absolute-imports';

  final Map<String, bool> _visitorMap = {};

  String _dirName = '';

  void reset() {
    _dirName = '';
    _visitorMap.clear();
  }

  /// Method which returns back the dependant's paths of a class file.
  Set<String> getDependenciesPath(String filePath) {
    _dirName = path.dirname(filePath);
    final paths = _getDependenciesPath(filePath);
    reset();

    return paths;
  }

  List<String> convertImportStatementsToAbsolutePaths(
    String filePath,
    String contents, {
    String directory = 'lib',
  }) {
    final importLines = _getImportLines(contents);

    final res = importLines.entries.map((value) => '${value.key}: ${value.value}').join('\n');
    Logger.d('File: $filePath:\n $res');

    final relativeImportLines = importLines[_relativeImportsConst] ?? const [];
    final absoluteImportLines = importLines[_absoluteImportsConst] ?? const [];

    final paths = <String>[];

    /// absolute import lines
    for (final import in absoluteImportLines) {
      paths.add(path.join(Utils.projectDirectory, directory, import));
    }

    /// relative import lines
    for (final import in relativeImportLines) {
      paths.add(path.normalize(path.join(_dirName, import)));
    }

    return paths;
  }

  bool _hasNotVisited(String filePath) {
    return _visitorMap[filePath] == null;
  }

  void _markVisited(String filePath) {
    _visitorMap[filePath] = true;
  }

  Set<String> _getDependenciesPath(String filePath) {
    final dependencies = <String>{};
    final contents = File(filePath).readAsStringSync();

    final imports = convertImportStatementsToAbsolutePaths(filePath, contents);

    final _ = dependencies.add(filePath);

    /// Find out transitive dependencies
    for (final import in imports) {
      /// There can be a cyclic dependency, so to make sure we are not visiting the same node multiple times
      if (_hasNotVisited(import)) {
        _markVisited(import);
        // ignore: avoid-recursive-calls, recursive call is ok.
        final transitiveDependencies = _getDependenciesPath(import);
        dependencies.addAll(transitiveDependencies);
      }
    }

    return dependencies;
  }

  Map<String, List<String>> _getImportLines(String dartSource) {
    final relativeImports = <String>[];
    final absoluteImports = <String>[];

    final lines = dartSource.split('\n');

    for (final line in lines) {
      final relativeMatch = Constants.relativeOrPartFileImportRegex.firstMatch(line);
      final packageMatch = Constants.appPackageImportRegex.firstMatch(line);

      if (relativeMatch != null) {
        final importedPath = relativeMatch.group(1);
        Logger.i('Rel. import: $line -> $importedPath');
        if (importedPath != null) {
          relativeImports.add(importedPath);
        }
      }

      if (packageMatch != null) {
        Logger.d('Package import: ${packageMatch.groups([0, 1]).map((e) => e.toString())}');
        final importedPath = packageMatch.group(1);
        if (importedPath != null) {
          absoluteImports.add(importedPath);
        }
      }
    }

    return {
      _absoluteImportsConst: absoluteImports,
      _relativeImportsConst: relativeImports,
    };
  }
}
