import 'dart:io';

import 'package:cached_build_runner/model/code_file.dart';
import 'package:cached_build_runner/utils/logger.dart';
import 'package:cached_build_runner/utils/utils.dart';

class BuildRunnerWrapper {
  const BuildRunnerWrapper();
  bool runBuild(List<CodeFile> files) {
    if (files.isEmpty) return true;
    Logger.header(
      'Generating Codes for non-cached files, found ${files.length} files',
    );

    /// following command needs to be executed
    /// flutter pub run build_runner build --build-filter="..." -d
    /// where ... contains the list of files that needs generation
    Logger.v('Running build_runner build...', showPrefix: false);

    final filterList = _getBuildFilterList(files);

    /// TODO: let's check how we can use the build_runner package and include in this project
    /// instead of relying on the flutter pub run command
    /// there can be issues with flutter being in the path.
    final process = Process.runSync(
      'flutter',
      [
        'pub',
        'run',
        'build_runner',
        'build',
        '--build-filter',
        filterList,
        '--delete-conflicting-outputs',
      ],
      workingDirectory: Utils.projectDirectory,
    );

    if (process.stderr.toString().isNotEmpty || process.exitCode != 0) {
      if (process.stdout.toString().isNotEmpty) Logger.e('BUILD_RUNNER failed!\n${process.stdout.toString().trim()}');

      if (process.stderr.toString().isNotEmpty) {
        Logger.e(process.stderr.toString().trim());
      }

      return false;
    }
    Logger.v(process.stdout.toString().trim(), showPrefix: false);

    return true;
  }

  /// Returns a comma-separated string of the file paths from the given list of [CodeFile]s
  /// formatted for use as the argument for the --build-filter flag in the build_runner build command.
  ///
  /// The method maps the list of [CodeFile]s to a list of generated file paths, and then
  /// returns a comma-separated string of the generated file paths.
  ///
  /// For example:
  ///
  /// final files = [CodeFile(path: 'lib/foo.dart', digest: 'abc123')];
  /// final buildFilter = _getBuildFilterList(files);
  /// print(buildFilter); // 'lib/foo.g.dart'.
  String _getBuildFilterList(List<CodeFile> files) {
    final paths = files.map<String>((x) => x.getGeneratedFilePath()).toList();

    return paths.join(',');
  }
}
