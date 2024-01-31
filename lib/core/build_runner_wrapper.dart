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

    // CLEANUP import files
    // for (final file in files.where((element) => element.generatedType == CodeFileGeneratedType.import)) {
    //   final f = File(file.getGeneratedFilePath());

    //   if (f.existsSync()) f.deleteSync();
    // }

    /// TODO: let's check how we can use the build_runner package and include in this project
    /// instead of relying on the flutter pub run command
    /// there can be issues with flutter being in the path.

    Logger.v('Run: "flutter pub run build_runner build --build-filter $filterList"');
    final process = Process.runSync(
      'flutter',
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs', '--build-filter', filterList],
      workingDirectory: Utils.projectDirectory,
    );
    final stdOut = process.stdout?.toString() ?? '';
    final stdErrr = process.stderr?.toString() ?? '';
    Logger.v(stdOut.trim(), showPrefix: false);
    Logger.v(stdErrr.trim(), showPrefix: false);

    return process.exitCode == 0;
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
    final paths = files.map<String>((x) => x.getSourceFilePath()).toList();

    return paths.join(',');
  }
}
