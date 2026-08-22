import 'package:talker/talker.dart';

export 'package:talker/talker.dart' show LogLevel;

/// Shared application logger backed by Talker.
///
/// Talker owns the in-memory log history and console output; this facade
/// only keeps call sites concise. Logs are deliberately not written to disk.
///
/// Keep authentication tokens, subscription URLs, and full proxy
/// configurations out of messages sent here.
abstract final class AppLogger {
  static final Talker talker = Talker(
    settings: TalkerSettings(maxHistoryItems: 2000),
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(enableColors: false),
      formatter: const _PlainLineFormatter(),
    ),
  );

  static void trace(String message, {String source = 'APP'}) =>
      _record(message, LogLevel.verbose, source);

  static void debug(String message, {String source = 'APP'}) =>
      _record(message, LogLevel.debug, source);

  static void info(String message, {String source = 'APP'}) =>
      _record(message, LogLevel.info, source);

  static void warning(
    String message, {
    String source = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _record(message, LogLevel.warning, source, error, stackTrace);

  static void error(
    String message, {
    String source = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _record(message, LogLevel.error, source, error, stackTrace);

  static void fatal(
    String message, {
    String source = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _record(message, LogLevel.critical, source, error, stackTrace);

  static void log(LogLevel level, String message, {String source = 'APP'}) =>
      _record(message, level, source);

  static void clear() => talker.cleanHistory();

  static void _record(
    String message,
    LogLevel level,
    String source, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    talker.logCustom(
      TalkerLog(
        _withError(message, error),
        title: source,
        logLevel: level,
        stackTrace: stackTrace,
      ),
    );
  }

  static String _withError(String message, Object? error) =>
      error == null ? message : '$message: $error';
}

/// Prints each log as a single plain line without box borders or colors.
class _PlainLineFormatter implements LoggerFormatter {
  const _PlainLineFormatter();

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) =>
      details.message?.toString() ?? '';
}
