import 'dart:io';

Future<void> formatDart(File file) async {
  await Process.run('dart', ['format', file.path]);
}
