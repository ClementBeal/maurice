import 'dart:io';

class FileContent {
  final Map<String, dynamic> arguments;
  final String markdown;

  FileContent({required this.arguments, required this.markdown});
}

FileContent? parseFile(File file) {
  final lines = file.readAsLinesSync();

  int i = 0;

  while (i < lines.length) {
    if (lines[i].startsWith("---")) {
      final args = Map.fromEntries(
        lines.sublist(0, i).where((line) => line.isNotEmpty).map(
          (e) {
            final index = e.indexOf(":");
            final key = e.substring(0, index).trim();
            final value = e.substring(index + 1).trim();

            return MapEntry(key, value);
          },
        ),
      );

      final markdown = lines.sublist(i + 1).join("\n");

      return FileContent(arguments: args, markdown: markdown);
    }

    i++;
  }

  final args = Map.fromEntries(
    lines.where((line) => line.isNotEmpty).map(
      (e) {
        final index = e.indexOf(":");
        final key = e.substring(0, index).trim();
        final value = e.substring(index + 1).trim();

        return MapEntry(key, value);
      },
    ),
  );

  return FileContent(arguments: args, markdown: "");
}
