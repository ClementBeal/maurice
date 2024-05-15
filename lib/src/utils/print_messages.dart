import 'dart:io';

class PrintMessage {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';

  static void error(String message) {
    stdout.write('$_red$message$_reset\n');
  }

  static void info(String message) {
    stdout.write('$_yellow$message$_reset\n');
  }

  static void success(String message) {
    stdout.write('$_green$message$_reset\n');
  }

  static void question(String message) {
    stdout.write('$_yellow$message$_reset ');
  }
}
