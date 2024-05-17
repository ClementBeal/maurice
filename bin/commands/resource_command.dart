import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:maurice/maurice.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';

class ResourceCommand extends Command {
  @override
  final name = "resource";
  @override
  final description = "Handle a resource";

  ResourceCommand() {
    addSubcommand(CreateResourceCommand());
    addSubcommand(NewResourceCommand());
    addSubcommand(PublishResourceCommand());
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }
  }
}

/// Add a new resource data for a given resource name
/// It will be use to generate pages
///
///  `maurice resource new <resource name>`
class NewResourceCommand extends Command {
  @override
  String get description => "Add a new resource";

  @override
  String get name => "new";

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    if (argResults!.rest.isEmpty) {
      PrintMessage.error("Please give the type of resource to create");
      exit(0);
    }

    final resource = argResults!.rest.first;

    // we need the resource template to generate the new resource
    final templateFile = File(p.join("resources", resource, "_$resource.md"));
    final data = parseFile(templateFile);

    final inputs = <String, String>{};

    // we ask for a filename
    final placeholder = askQuestion("A name for the file like a sentence");

    // we ask questions to fill the needed data for the template
    for (var e in data!.arguments.entries) {
      inputs[e.key] = askQuestion(e.key);
    }

    final lastFile = Directory(p.join("resources", resource))
        .listSync()
        .whereType<Directory>()
        .lastOrNull;

    // we parse the filename of the lastfile to get its id
    // if it's empty, the new ID is 1
    // otherwise we increment the id
    final nextId = (lastFile == null)
        ? 1
        : int.parse(
                p.basenameWithoutExtension(lastFile.path).split("-").first) +
            1;

    // the format is "<id>-<filename>.md"
    final filename = "$nextId-${slugify(placeholder)}.md";

    final template = Template(
      File(p.join("resources", resource, "_$resource.md")).readAsStringSync(),
      name: "_$resource.md",
      htmlEscapeValues: false,
    );

    // we create a new folder for the resources because we might need to associate medias to it
    // the resource may need images later
    Directory(p.join("resources", resource, "$nextId-${slugify(placeholder)}"))
        .createSync();

    // eg: data/post/1-my-example/1-my-example.md
    final outputFile = File(
      p.join(
        "resources",
        resource,
        "$nextId-${slugify(placeholder)}",
        filename,
      ),
    )..writeAsStringSync(
        template.renderString(inputs),
      );

    PrintMessage.success(
      "New resource of type $resource created : ${outputFile.absolute.path}",
    );
  }
}

/// Publish a resource
/// The resource will be available for the pages generation
///
/// `maurice resource publish <resource name> <resource id>`
class PublishResourceCommand extends Command {
  @override
  String get description => "Publish a resource";

  @override
  String get name => "publish";

  @override
  void run() {
    if (argResults == null || argResults!.rest.isEmpty) {
      PrintMessage.error("You need to specify the resource id (eg: 23)");
      return;
    }

    final resourceName = argResults!.rest.first;
    final resourceId = int.parse(argResults!.rest[1]);

    // we look for the resource with the given id
    final file = Directory(p.join("resources", resourceName))
        .listSync()
        .whereType<File>()
        .firstWhereOrNull(
          (element) => p
              .basenameWithoutExtension(element.path)
              .startsWith("$resourceId-"),
        );

    if (file == null) {
      PrintMessage.error("We can't find a resource with the id $resourceId");
      return;
    }

    final lines = file.readAsLinesSync();

    int i = 0;

    // look for the "published" line and update it with the current date
    // otherwise it insert the new line before the separator "---"
    while (i < lines.length) {
      final line = lines[i];
      if (line.startsWith("published")) {
        lines[i] = "published: ${DateTime.now().toIso8601String()}";
        break;
      }
      if (line.startsWith("---")) {
        lines.insert(i - 1, "published: ${DateTime.now().toIso8601String()}");
        break;
      }

      i++;
    }

    file.writeAsStringSync(lines.join("\n"));
  }
}

/// Create a new kind of resource for the project
/// It will ask questions to generate the template
///
/// `maurice resource create <resource name>`
class CreateResourceCommand extends Command {
  @override
  String get description => "Create a new type of resource";

  @override
  String get name => "create";

  @override
  void run() {
    if (argResults == null || argResults!.rest.isEmpty) {
      PrintMessage.error("You need to specify a resource name");
      return;
    }

    final resourceName = argResults!.rest.first;

    Directory(p.join("resources", resourceName)).createSync();
    final inputs = <String>[];

    inputs.add(askQuestion("Add a field to the template"));

    while (askChoiceQuestion("One more?")) {
      inputs.add(askQuestion("Add a field to the template"));
    }

    // generate lines like this : "title: {{ title }}"
    final template = inputs
        .map(
          (e) => "$e: {{ $e }}",
        )
        .join("\n");

    File(p.join("resources", resourceName, "_$resourceName.md"))
        .writeAsStringSync(template);
  }
}
