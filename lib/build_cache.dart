import 'dart:io';

import 'package:build_cache/database/database_service.dart';
import 'package:build_cache/model/code_file.dart';
import 'package:build_cache/utils/log.dart';
import 'package:build_cache/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class BuildCache {
  DatabaseService _databaseService;

  BuildCache(
    this._databaseService,
  );

  /// this method runs an efficient version of `build_runner build`
  Future<void> build() async {
    final files = _fetchRequiredFilePaths();

    final List<CodeFile> goodFiles = [];
    final List<CodeFile> badFiles = [];

    /// segregate good and bad files
    /// good files -> files for whom the generated codes are available
    /// bad files -> files for whom no generated codes are available in the cache
    for (final file in files) {
      final isGeneratedCodeAvailable = _databaseService.isMappingAvailable(file.digest);
      if (isGeneratedCodeAvailable) {
        goodFiles.add(file);
      } else {
        badFiles.add(file);
      }
    }

    /// let's handle the good files - by copying the cached generated files to appropriate path
    /// we pass in the bad files as well, in case the good files could not be copied,
    /// they become bad files - though this should NOT happen, still a safe mechanism to avoid complete error
    _copyGeneratedCodesFor(goodFiles, badFiles);

    /// let's handle bad files - by generating the .g.dart files for them
    _generateCodesFor(badFiles);

    /// at last, let's cache the bad files - they may be required next time
    _cacheGeneratedCodesFor(badFiles);

    /// We are done, probably?
  }

  void _copyGeneratedCodesFor(List<CodeFile> files, List<CodeFile> badFiles) {
    for (final file in files) {
      final cachedGeneratedCodePath = _databaseService.getCachedFilePath(file.digest);
      final process = Process.runSync(
        'cp',
        [
          cachedGeneratedCodePath,
          _convertPathFromDartToGDart(file.path),
        ],
      );

      print(process.stderr);

      /// check if the file was copied successfully
      if (!File(_convertPathFromDartToGDart(file.path)).existsSync()) {
        Logger.log('ERROR: _copyGeneratedCodesFor: filed to copy the cached file $file');
        badFiles.add(file);
      }
    }
  }

  /// converts ".../cta_model.dart" to ".../cta_model.g.dart"
  String _convertPathFromDartToGDart(String input) {
    final lastDotDart = input.lastIndexOf('.dart');
    if (lastDotDart >= 0) {
      return '${input.substring(0, lastDotDart)}.g.dart';
    }
    return input;
  }

  String _getBuildFilterList(List<CodeFile> files) {
    return files.map((file) => _convertPathFromDartToGDart(file.path)).join(',');
  }

  /// this method runs build_runner build method with --build-filter
  /// to only generate the required codes, thus avoiding unnecessary builds
  void _generateCodesFor(List<CodeFile> files) {
    /// following command needs to be executed
    /// flutter pub run build_runner build --build-filter="..." -d
    /// where ... contains the list of files that needs generation

    final process = Process.runSync(
      'flutter',
      [
        'pub',
        'run',
        'build_runner',
        'build',
        '--build-filter',
        _getBuildFilterList(files),
        '--delete-conflicting-outputs'
      ],
    );

    print(process.stdout);
  }

  /// this method returns all the files that needs code generations
  List<CodeFile> _fetchRequiredFilePaths() {
    final regExp = RegExp(r"part '.+\.g\.dart';");

    final process = Process.runSync(
      'grep',
      ['-r', '-l', '-E', regExp.pattern, path.join(Utils.projectDirectory, 'lib')],
      runInShell: true,
    );

    final pathList = process.stdout.toString().split("\n").where(
          (line) => line.isNotEmpty && !line.endsWith(".g.dart"),
        );

    return pathList
        .map<CodeFile>(
          (path) => CodeFile(
            path: path,
            digest: md5.convert(File(path).readAsBytesSync()).toString(),
          ),
        )
        .toList(growable: false);
  }

  /// copies the generated files to cache directory, and make an entry in database
  void _cacheGeneratedCodesFor(List<CodeFile> files) async {
    for (final file in files) {
      final cachedFilePath = path.join(Utils.appCacheDirectory, file.digest);
      final process = Process.runSync(
        'cp',
        [
          _convertPathFromDartToGDart(file.path),
          path.join(Utils.appCacheDirectory, file.digest),
        ],
      );

      print(process.stderr);

      /// if file has been successfully copied, let's make an entry to the db
      if (File(cachedFilePath).existsSync()) {
        await _databaseService.createEntry(file.digest, cachedFilePath);
      } else {
        Logger.log('ERROR: _cacheGeneratedCodesFor: failed to copy generated file $file');
      }
    }
  }
}
