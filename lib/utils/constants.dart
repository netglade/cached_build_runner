import 'package:cached_build_runner/utils/utils.dart';

class Constants {
  static const String pubpsecLockFileName = 'pubspec.lock';

  /// Regex match "generated" file "suffix".
  ///
  /// E.g.:
  ///
  /// `user.g.dart` -> matches with `g`
  ///
  /// `user.freezed.dart` -> matches `freezed`.
  static final partFileExtensionRegex = RegExp(r'.+\..+\.dart');

  /// Regex matches part file with "generated" file. Group 1 match suffix.
  /// Handles relative parts as well.
  ///
  /// E.g.:
  ///
  /// `part user.g.dart` -> matches with `g`
  ///
  /// `part user.freezed.dart` -> matches with `freezed`.
  static final partGeneratedFileRegex = RegExp(r"part '.+\.(.+)\.dart';");

  /// Regex matches part files except with "generated" suffix.
  /// Handles relative parts as well.
  /// E.g.:
  ///
  /// `part user.dart` -> matches
  ///
  /// `part user.freezed.dart` -> does not.
  static final partFileRegex = RegExp(r'''^part\s+['\"]((?:.+\/)*[^\.]+\.dart)['\"];''');

  /// Regex matches any `import package:PACKAGE/...` - any import within same package.
  ///
  /// E.g.:
  ///
  /// `import 'package:PACKAGE/foo.dart'` -> matches
  ///
  /// `import 'package:json_serializable/json_serializable.dart'` -> doesn't match.
  static final appPackageImportRegex =
      RegExp('import\\s+[\'"]package:${Utils.appPackageName}/(.*)[\'"];', multiLine: true);

  /// Regex matches any relative import or part file except generated ones.
  ///
  /// E.g.:
  ///```
  /// import 'x.dart' -> matches
  /// import '../../x.dart' -> matches
  /// import 'x/z.dart' -> matches
  /// part 'x.dart' -> matches
  ///
  /// import 'package:json_serializable/json_serializable.dart' -> doesn't match.
  /// import 'x.g.dart' -> doesn't match.
  /// part 'x.g.dart' -> doesn't match.
  /// ```
  static final relativeOrPartFileImportRegex = RegExp(
    r'''^\s*(?:import|part)\s+(?:\'|\")((?:(?!package:).+\/[^\.]+.dart)|(?:(?!package:)[^\.\/]+.dart))(?:\'|\")\s*;''',
    multiLine: true,
  );

  /// Regex matches any import with generated part except "foo.g.dart" part.
  ///
  /// E.g.:
  ///```
  /// import 'package:PACAKGE/x.auto_mappr.dart' -> matches
  ///
  /// import 'package:PACAKGE/x.g.dart' -> doesn't match.
  /// ```
  static final generatedFileImportRegExp = RegExp(r'''import\s+['\"].+\.([^g\/\.].*|g.+)\.dart['\"]''');
}
