import 'dart:io';

class FileContent {
  /// All the arguments contains in the first block.
  /// eg: "title: My title" or "github_url: https://github.com/user/project"
  final Map<String, dynamic> arguments;

  /// the second block is usually either markdown or HTML depending of the file extension
  final String markdown;

  FileContent({required this.arguments, required this.markdown});
}

/// Parse the content of a file.
/// The file is made of 2 blocks separated by "---"
/// The second block is optional.
FileContent? parseFile(File file) {
  return parseContent(file.readAsLinesSync());
}

FileContent? parseContent(List<String> lines) {
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

  // in this case, there's no "---" and so there's only one block
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
