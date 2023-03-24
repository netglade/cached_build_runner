import 'package:logger/logger.dart' as logger;

import 'utils.dart';

class Logger {
  static final _logger = logger.Logger(
    filter: _LogFilter(),
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      printTime: false,
      noBoxingByDefault: true,
    ),
  );

  static final _loggerWithBox = logger.Logger(
    filter: _LogFilter(),
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      printTime: false,
    ),
  );

  static v(String message) {
    _logger.v('│ $message');
  }

  static i(String message) {
    _loggerWithBox.i(message);
  }

  static e(String message) {
    _loggerWithBox.e(message);
  }
}

class _LogFilter extends logger.LogFilter {
  @override
  bool shouldLog(logger.LogEvent event) {
    if (event.level == logger.Level.error) return true;
    return Utils.isVerbose;
  }
}
