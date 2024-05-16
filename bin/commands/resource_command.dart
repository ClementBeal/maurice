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
    final templateFile = File(p.join("data", resource, "_$resource.md"));
    final data = parseFile(templateFile);

    final inputs = <String, String>{};

    final placeholder = askQuestion("A name for the file like a sentence");

    for (var e in data!.arguments.entries) {
      inputs[e.key] = askQuestion(e.key);
    }

    final lastFile = Directory(p.join("data", resource))
        .listSync()
        .whereType<Directory>()
        .lastOrNull;

    final nextId = (lastFile == null)
        ? 1
        : int.parse(
                p.basenameWithoutExtension(lastFile.path).split("-").first) +
            1;

    final filename = "$nextId-${slugify(placeholder)}.md";

    final template = Template(
      File(p.join("data", resource, "_$resource.md")).readAsStringSync(),
      name: "_$resource.md",
      htmlEscapeValues: false,
    );

    Directory(p.join("data", resource, "$nextId-${slugify(placeholder)}"))
        .createSync();
    Directory(p.join(
            "data", resource, "$nextId-${slugify(placeholder)}", "images"))
        .createSync();

    // eg: data/post/1-my-example/1-my-example.md
    final outputFile = File(
      p.join(
        "data",
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

    final postId = int.parse(argResults!.rest.first);

    final file = Directory("posts")
        .listSync()
        .whereType<File>()
        .firstWhereOrNull(
          (element) =>
              p.basenameWithoutExtension(element.path).startsWith("$postId-"),
        );

    if (file == null) {
      PrintMessage.error("We can't find a resource with the id $postId");
      return;
    }

    final lines = file.readAsLinesSync();

    int i = 0;

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

    Directory(p.join("data", resourceName)).createSync();
    final inputs = <String>[];

    inputs.add(askQuestion("Add a field to the template"));

    while (askChoiceQuestion("One more?")) {
      inputs.add(askQuestion("Add a field to the template"));
    }

    File(p.join("data", resourceName, "_$resourceName.md")).writeAsStringSync(
      inputs
          .map(
            (e) => "$e: {{ $e }}",
          )
          .join("\n"),
    );
  }
}
