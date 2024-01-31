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
    Logger.d('Depdencies for $filePath');
    final paths = _getDependenciesPath(filePath);

    Logger.d('=================================');
    reset();

    return paths;
  }

  List<String> _convertImportStatementsToAbsolutePaths(
    String filePath,
    String contents, {
    String directory = 'lib',
  }) {
    Logger.d('File: $filePath');

    final importLines = _getImportLines(contents);
    final res = importLines.entries.map((value) => '${value.key}: ${value.value}').join('\n');
    Logger.d('$res\n');

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

    final imports = _convertImportStatementsToAbsolutePaths(filePath, contents);

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

    final relativeMatches = Constants.relativeOrPartFileImportRegex.allMatches(dartSource);
    final packageMatches = Constants.appPackageImportRegex.allMatches(dartSource);

    for (final match in relativeMatches) {
      final importedPath = match.group(1);
      if (importedPath != null) {
        Logger.d('Rel. import -> $importedPath');

        relativeImports.add(importedPath);
      }
    }

    for (final match in packageMatches) {
      final importedPath = match.group(1);
      if (importedPath != null) {
        Logger.d('Abs. import -> $importedPath');
        absoluteImports.add(importedPath);
      }
    }

    // for (final line in dartSource.split('\n')) {
    //   final relativeMatch = Constants.relativeOrPartFileImportRegex.firstMatch(line);
    //   final packageMatch = Constants.appPackageImportRegex.firstMatch(line);

    //   if (relativeMatch != null) {
    //     final importedPath = relativeMatch.group(1);
    //     if (importedPath != null) {
    //       Logger.d('Rel. import -> $importedPath');
    //       relativeImports.add(importedPath);
    //     }
    //   }

    //   if (packageMatch != null) {
    //     final importedPath = packageMatch.group(1);
    //     if (importedPath != null) {
    //       Logger.d('Package import: ${packageMatch.groups([0, 1]).map((e) => e.toString())}');
    //       absoluteImports.add(importedPath);
    //     }
    //   }
    // }

    return {
      _absoluteImportsConst: absoluteImports,
      _relativeImportsConst: relativeImports,
    };
  }
}
