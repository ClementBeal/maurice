import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';

class PageCommand extends Command {
  @override
  final name = "page";
  @override
  final description = "Create a page";

  PageCommand() {
    addSubcommand(NewPageCommand());
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }
  }
}

class NewPageCommand extends Command {
  @override
  String get description => "Add a new page";

  @override
  String get name => "new";

  @override
  void run() {
    String title = "";
    String description = "";

    while (title.isEmpty) {
      title = askQuestion("Title of the page");
    }
    while (description.isEmpty) {
      description = askQuestion("Description of the page");
    }

    final filename = "${slugify(title)}.html";

    final template = Template(
        File(getTemplatePath("_page.html")).readAsStringSync(),
        name: "_page.html",
        htmlEscapeValues: false);

    final outputFile = File(
      p.join(
        "pages",
        filename,
      ),
    )..writeAsStringSync(
        template.renderString(
          {
            "title": title,
            "description": description,
          },
        ),
      );

    PrintMessage.success("New page created : ${outputFile.absolute.path}");
  }
}
