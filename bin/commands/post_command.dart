import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:maurice/maurice.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';

class PostCommand extends Command {
  @override
  final name = "post";
  @override
  final description = "Create or delete a post";

  PostCommand() {
    addSubcommand(NewPostCommand());
    addSubcommand(PublishPostCommand());
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }
  }
}

class NewPostCommand extends Command {
  @override
  String get description => "Add a new post";

  @override
  String get name => "new";

  @override
  void run() {
    String title = "";
    String description = "";

    while (title.isEmpty) {
      title = askQuestion("Title of the post");
    }
    while (description.isEmpty) {
      description = askQuestion("Description of the post");
    }

    final lastFile =
        Directory("posts").listSync().whereType<Directory>().lastOrNull;

    final nextId = (lastFile == null)
        ? 1
        : int.parse(
                p.basenameWithoutExtension(lastFile.path).split("-").first) +
            1;

    final filename = "$nextId-${slugify(title)}.md";

    final template = Template(
        File(getTemplatePath("_post.md")).readAsStringSync(),
        name: "_post.md",
        htmlEscapeValues: false);

    Directory(p.join("posts", "$nextId-${slugify(title)}")).createSync();
    Directory(p.join("posts", "$nextId-${slugify(title)}", "images"))
        .createSync();

    final outputFile = File(
      p.join(
        "posts",
        "$nextId-${slugify(title)}",
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

    PrintMessage.success("New post created : ${outputFile.absolute.path}");
  }
}

class PublishPostCommand extends Command {
  @override
  String get description => "Publish a post";

  @override
  String get name => "publish";

  @override
  void run() {
    if (argResults == null || argResults!.rest.isEmpty) {
      PrintMessage.error("You need to specify the post id (eg: 23)");
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
      PrintMessage.error("We can't find a post with the id $postId");
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
