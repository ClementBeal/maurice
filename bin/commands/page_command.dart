import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';
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
    final inputs = <String, dynamic>{};

    final isUsingResources = askChoiceQuestion(
        "Does this page use a resource to generate its content?");
    String resourceName;

    if (isUsingResources) {
      resourceName = askQuestion("What is the resource to use?");
      while (!Directory(p.join("data", resourceName)).existsSync()) {
        PrintMessage.error("The resource $resourceName does not exist");
        resourceName = askQuestion("What is the resource to use?");
      }

      inputs["use_resource"] = resourceName;

      inputs["one_page_per_item"] = askChoiceQuestion(
          "Should we generate one page for each $resourceName?");

      if (inputs["one_page_per_item"]) {
        inputs["route"] =
            askQuestion("Define a route for the items (eg: /$resourceName/)");
      } else {
        final needsPagination = askChoiceQuestion("Does it need pagination?");

        if (needsPagination) {
          inputs["use_pagination"] = needsPagination;
          inputs["items_per_page"] =
              askNumericQuestion("How many items per page?");
        } else {
          inputs["inject_resource"] = true;
        }
      }
    }

    if (!(inputs["use_resource"] != null)) {
      while (inputs["title"]!.isEmpty) {
        inputs["title"] = askQuestion("Title of the page (SEO)");
      }
      while (inputs["description"]!.isEmpty) {
        inputs["description"] = askQuestion("Description of the page (SEO)");
      }
    }

    final filename =
        "${slugify(inputs["use_resource"] ?? inputs["title"])}.html";

    final outputFile = File(
      p.join(
        "pages",
        filename,
      ),
    )..writeAsStringSync(inputs.entries
        .map(
          (e) => "${e.key}: ${e.value}",
        )
        .join("\n"));

    PrintMessage.success("New page created : ${outputFile.absolute.path}");
  }
}
