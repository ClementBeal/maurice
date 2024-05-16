import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:markdown/markdown.dart';
import 'package:maurice/maurice.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

class BuildCommand extends Command {
  @override
  final name = "build";
  @override
  final description = "Build the project into html files";

  late String baseHtml;
  late String postHtml;
  late String outputPath;
  late String postOutputFile;
  late Template baseTemplate;
  late Template postTemplate;

  BuildCommand();

  void _load() {
    baseHtml = File("layouts/_base.html").readAsStringSync();
    postHtml = File("layouts/_post.html").readAsStringSync();

    Directory("output").createSync();
    outputPath = "output";
    postOutputFile = p.join(outputPath, "posts");
    Directory(postOutputFile).createSync();

    baseTemplate =
        Template(baseHtml, name: "_base.html", htmlEscapeValues: false);
    postTemplate =
        Template(postHtml, name: "_post.html", htmlEscapeValues: false);
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    _load();

    _buildPages();
    _buildAssets();

    final postFiles = Directory("posts").listSync().whereType<Directory>();

    for (var f in postFiles) {
      final data = parseFile(
        File(p.join(
          f.path,
          p.setExtension(p.basenameWithoutExtension(f.path), ".md"),
        )),
      );

      if (data == null) {
        PrintMessage.error("The follow post is incorrect : ${f.absolute.path}");
        exit(0);
      }

      final renderedPostHtml = postTemplate.renderString(
        {
          "post": {"content": markdownToHtml(data.markdown)},
        },
      );

      final filename = p.basenameWithoutExtension(f.path);
      final name = filename.split("-").skip(1).join("-");

      File(p.join(postOutputFile, "$name.html")).writeAsStringSync(
        baseTemplate.renderString(
          {
            "body": renderedPostHtml,
            "page": {
              "title": data.arguments["title"],
              "description": data.arguments["description"],
            }
          },
        ),
      );
    }
  }

  void _buildAssets() {
    final templatesFolder = Directory("assets");
    Directory(p.join(outputPath, "assets")).createSync();

    templatesFolder.listSync(recursive: true).forEach(
      (element) {
        final rest = element.path.split("assets/").last;
        if (element is Directory) {
          Directory(p.join(outputPath, "assets", rest)).createSync();
        } else if (element is File) {
          element.copySync(p.join(outputPath, "assets", rest));
        }
      },
    );
  }

  void _buildPages() {
    final pagesFiles = Directory("pages").listSync().whereType<File>().where(
          (e) => p.extension(e.path) == ".html",
        );

    for (var page in pagesFiles) {
      final filename = p.basename(page.path);
      final data = parseFile(page);

      if (data == null) {
        PrintMessage.error(
            "The following page is incorrect : ${page.absolute.path}");
        exit(0);
      }

      final output = baseTemplate.renderString(
        {
          "body": data!.markdown,
          "page": {
            "title": data.arguments["title"],
            "description": data.arguments["description"],
          }
        },
      );

      File(p.join(outputPath, filename)).writeAsString(output);
    }
  }

  void _generateSitemap() {}
}
