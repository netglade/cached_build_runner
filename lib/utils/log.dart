import 'package:logger/logger.dart' as logger;

import 'utils.dart';

/// A class that provides logging functionality.
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

  /// Logs a verbose message.
  ///
  /// If [showPrefix] is `true`, the message will be prefixed with a vertical bar.
  static v(String message, {bool showPrefix = true}) {
    _logger.v('${showPrefix ? '│ ' : ''}$message');
  }

  /// Logs an information message.
  static i(String message) {
    _loggerWithBox.i(message);
  }

  /// Logs an error message.
  static e(String message) {
    _loggerWithBox.e(message);
  }
}

class _LogFilter extends logger.LogFilter {
  /// Returns `true` if the given [event] should be logged, based on the current logging settings.
  ///
  /// This implementation logs all events with level [logger.Level.error] and events with other levels only if [Utils.isVerbose] is `true`.
  @override
  bool shouldLog(logger.LogEvent event) {
    if (event.level == logger.Level.error) return true;
    return Utils.isVerbose;
  }
}
