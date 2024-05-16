import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';

class BuildCommand extends Command {
  @override
  final name = "build";
  @override
  final description = "Build the project into html files";

  late String baseHtml;
  late String outputPath;
  late Template baseTemplate;

  BuildCommand();

  /// Prepare the build environment
  /// We load the base template, clean the output folder and that's it
  void _load() {
    baseHtml = File("layouts/_base.html").readAsStringSync();

    Directory("output")
      ..deleteSync(recursive: true)
      ..createSync();
    outputPath = "output";

    baseTemplate =
        Template(baseHtml, name: "_base.html", htmlEscapeValues: false);
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    _load();

    _buildPages();
    _buildAssets();
  }

  /// copy the assets folder to the output
  /// TODO : check if the images can be converted to be a better format(webp)
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

      if (data.arguments["use_resource"] != null) {
        final template =
            Template(data.markdown, name: page.path, htmlEscapeValues: false);

        final String resource = data.arguments["use_resource"];

        final resourceFiles = Directory(p.join("data", resource))
            .listSync()
            .whereType<Directory>()
            .map(
              (e) => File(
                p.join(
                  e.path,
                  p.setExtension(p.basenameWithoutExtension(e.path), ".md"),
                ),
              ),
            );

        final bool generateMultiplePages =
            data.arguments["one_page_per_item"] == "true";

        if (generateMultiplePages) {
          final String route = data.arguments["route"];
          final resourceOutputFolder = Directory(p.join(outputPath, route))
            ..createSync();

          for (var resourceFile in resourceFiles) {
            final data = parseFile(resourceFile.absolute);
            final filename = p.join(
                resourceOutputFolder.path, slugify(data!.arguments["title"]));
            File(p.setExtension(filename, ".html"))
                .writeAsStringSync(template.renderString(data.arguments));
          }
        } else if (data.arguments["use_pagination"]) {}
      } else {
        final output = baseTemplate.renderString(
          {
            "body": data.markdown,
            "page": {
              "title": data.arguments["title"],
              "description": data.arguments["description"],
            }
          },
        );

        File(p.join(outputPath, filename)).writeAsString(output);
      }
    }
  }
}
