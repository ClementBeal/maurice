import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:markdown/markdown.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

class BuildCommand extends Command {
  @override
  final name = "build";
  @override
  final description = "Build the project into html files";

  BuildCommand();

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    Directory("output").createSync();
    final outputPath = "output";
    final postOutputFile = p.join(outputPath, "posts");
    Directory(postOutputFile).createSync();

    final baseHtml = File("layouts/base.html").readAsStringSync();
    final postHtml = File("layouts/post.html").readAsStringSync();

    final baseTemplate =
        Template(baseHtml, name: "base.html", htmlEscapeValues: false);
    final postTemplate =
        Template(postHtml, name: "post.html", htmlEscapeValues: false);

    final postFiles = Directory("posts").listSync().whereType<File>().where(
          (e) => p.extension(e.path) == ".md",
        );

    for (var f in postFiles) {
      final lines = f.readAsLinesSync();
      final indexLine = lines.indexOf("---");
      final content = lines.sublist(indexLine + 1).join("\n");

      final renderedPostHtml = postTemplate.renderString(
        {
          "post": {"content": markdownToHtml(content)},
        },
      );

      final filename = p.basenameWithoutExtension(f.path);
      final name = filename.split("-").skip(1).join("-");

      File(p.join(postOutputFile, "$name.html")).writeAsStringSync(
        baseTemplate.renderString(
          {
            "body": renderedPostHtml,
            "title": "Test",
            "description": "Test description"
          },
        ),
      );
    }
  }
}
