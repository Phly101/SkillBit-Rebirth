// AI-generated (Claude), reviewed by the author.
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:skillbit_rebirth/core/logging/spring_style_printer.dart';

/// Small wrapper so the rest of the app never touches the logger package.
/// Usage: static final _log = AppLogger('AuthRepository');
class AppLogger {
  new(String name)
    : _logger = Logger(
        printer: SpringStylePrinter(name),
        // Release builds only show warnings and errors
        level: kReleaseMode ? Level.warning : Level.debug,
      );

  final Logger _logger;

  void debug(String message) => _logger.d(message);

  void info(String message) => _logger.i(message);

  void warn(String message) => _logger.w(message);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
