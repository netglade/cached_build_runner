import 'package:cached_build_runner/utils/utils.dart';

class Constants {
  static const String pubpsecLockFileName = 'pubspec.lock';
  static final generatedPartFileRegex = RegExp(r'.+\..+\.dart');

  static final packageImportRegExp = RegExp("import\\s+'package:${Utils.appPackageName}.+\\.([^g].*|g.+)\\.dart';");
  static final relativeImportRegExp = RegExp(r'''import\s+(?!(\w+:))(?:'|")(.*?)('|");?''');
}
