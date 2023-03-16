import 'utils.dart';

class Logger {
  static log(String message, {bool fatal = false}) {
    /// fatal logs are always printed
    if (Utils.isVerbose || fatal) print(message);
  }
}
