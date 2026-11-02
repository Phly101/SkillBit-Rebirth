import 'dart:isolate';

import 'package:logger/logger.dart';

class SpringStylePrinter extends LogPrinter {
  new(this.name);

  final String name;

  static String _color(int code, String text) => '\x1B[$code,$text\x1B[0m';

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  List<String> log(LogEvent event) {
    final t = event.time;
    final time =
        '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}'
        '.${t.millisecond.toString().padLeft(3, '0')}';
    final level = event.level.name.toUpperCase().padRight(5);
    final thread = Isolate.current.debugName ?? 'main';
    final logger = name.length > 15 ? name.substring(0, 15) : name.padRight(15);
    final lines = <String>[
      '${_color(32, time)} ${_color(34, level)} ${_color(31, '[$thread]')} ${_color(33, logger)} - ${event.message}',
    ];
    if (event.error != null) lines.add('${event.error}');
    if (event.stackTrace != null) lines.add('${event.stackTrace}');
    return lines;
  }
}
