import 'dart:io';

/// Print colorful messages in the console
class PrintMessage {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';

  /// Print an error message in red
  static void error(String message) {
    stdout.write('$_red$message$_reset\n');
  }

  /// Print an informative message in yellow
  static void info(String message) {
    stdout.write('$_yellow$message$_reset\n');
  }

  /// Print a successful message in green
  static void success(String message) {
    stdout.write('$_green$message$_reset\n');
  }

  /// Print a question message in yellow
  static void question(String message) {
    stdout.write('$_yellow$message$_reset ');
  }
}
