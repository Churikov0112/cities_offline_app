import 'package:logger/logger.dart';

enum LogLevel {
  debug,
  error,
  info,
  fatal,
  trace,
  warning,
}

class LogService {
  static final _logger = Logger(
    printer: PrettyPrinter(),
  );

  static void log(
    String message, {
    LogLevel level = LogLevel.debug,
    StackTrace? stackTrace,
  }) {
    switch (level) {
      case LogLevel.debug:
        _logger.d(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
      case LogLevel.error:
        _logger.e(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
      case LogLevel.info:
        _logger.i(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
      case LogLevel.fatal:
        _logger.f(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
      case LogLevel.trace:
        _logger.t(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        _logger.w(message, time: DateTime.now(), stackTrace: stackTrace);
        break;
    }
  }

  static void error(String message, [Object? error]) {
    _logger.e(message, time: DateTime.now(), error: error);
  }
}
