// AI-generated (Claude), reviewed by the author.
import 'dart:isolate';

import 'package:logger/logger.dart';

/// Prints logs like Spring Boot:
/// 12:31:05.123  INFO ['main'] ThemeCubit : message
class SpringStylePrinter extends LogPrinter {
  new(this.name);

  final String name;

  static const String _reset = '\x1B[0m';

  @override
  List<String> log(LogEvent event) {
    final time = _formatTime(event.time);
    final level = _levelName(event.level).padLeft(5);
    final thread = Isolate.current.debugName ?? 'main';
    final color = _color(event.level);

    final lines = <String>[
      '$time $color$level$_reset [$thread] $name : ${event.message}',
    ];
    if (event.error != null) lines.add('  error: ${event.error}');
    if (event.stackTrace != null) lines.add('${event.stackTrace}');
    return lines;
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.$ms';
  }

  static String _levelName(Level level) {
    switch (level) {
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO';
      case Level.warning:
        return 'WARN';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      default:
        return 'TRACE';
    }
  }

  static String _color(Level level) {
    switch (level) {
      case Level.info:
        return '\x1B[32m'; // green
      case Level.warning:
        return '\x1B[33m'; // yellow
      case Level.error:
      case Level.fatal:
        return '\x1B[31m'; // red
      default:
        return '\x1B[36m'; // cyan
    }
  }
}
