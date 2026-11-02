import 'package:logger/logger.dart';
import 'package:skillbit_rebirth/core/logging/spring_style_printer.dart';

Logger appLogger(String name) => Logger(printer: SpringStylePrinter(name));
