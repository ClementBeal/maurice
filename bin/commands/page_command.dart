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

    String route = askQuestion("Define a route (eg: /articles/how-to-fix)");

    final isUsingResources = askChoiceQuestion(
        "Does this page use a resource to generate its content?");
    String resourceName;

    if (isUsingResources) {
      resourceName = askQuestion("What is the resource to use?");

      while (!Directory(p.join("resources", resourceName)).existsSync()) {
        PrintMessage.error("The resource $resourceName does not exist");
        resourceName = askQuestion("What is the resource to use?");
      }

      inputs["use_resource"] = resourceName;

      inputs["one_page_per_item"] = askChoiceQuestion(
          "Should we generate one page for each $resourceName?");

      if (inputs["one_page_per_item"]) {
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

    inputs["_pageTitle"] = "";
    inputs["_pageDescription"] = "";

    final routeWithoutLeadingSlash = route.substring(1).trim();
    final filename = "$routeWithoutLeadingSlash.html";

    final outputFile = File(
      p.join(
        "pages",
        filename,
      ),
    );
    outputFile.parent.createSync(recursive: true);

    outputFile.writeAsStringSync(inputs.entries
        .map(
          (e) => "${e.key}: ${e.value}",
        )
        .join("\n"));

    PrintMessage.success("New page created : ${outputFile.absolute.path}");
  }
}
