import 'package:cached_build_runner/utils/utils.dart';

class Constants {
  static const String pubpsecLockFileName = 'pubspec.lock';
  static final partFileExtensionRegex = RegExp(r'.+\..+\.dart');
  static final partGeneratedFileRegex = RegExp(r"part '.+\.(.+)\.dart';");
  static final partFileRegex = RegExp(r'''^part\s+['\"]((?:.+\/)*[^\.]+\.dart)['\"];''');
  static final partOfFileRegex = RegExp("part of '(.+)';");

  //static final appPackageImportRegex = RegExp("import\\s+'package:${Utils.appPackageName}.+\\.dart';");
  static final appPackageImportRegex = RegExp('import\\s+[\'"]package:${Utils.appPackageName}/(.*)[\'"];');
  static final relativeOrPartFileImportRegex =
      RegExp(r'''^\h*(?:import|part)\h+(?:\'|\")((?:.+\/[^\.]+.dart)|(?:[^\.\/]+.dart))(?:\'|\")\h*;''');
  static final relativeImportRegex = RegExp(r'''import\s+(?!(\w+:))(?:'|")(.*?)('|");?''');

  // static final packageImportPartFileRegExp = RegExp(r"import\s+'package:.+\.([^g].*|g.+)\.dart';");
  // static final relativeImportPartFileRegExp = RegExp(r'''import\s+['\"](?!package:)(?<importPath>.*?)['\"]''');

  static final generatedFileImportRegExp = RegExp(r'''import\s+['\"].+\.([^g\/\.].*|g.+)\.dart['\"]''');
}
