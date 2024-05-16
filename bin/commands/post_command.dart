import 'dart:io';

import 'package:args/command_runner.dart';
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

    final lastFile = Directory("posts").listSync().whereType<File>().lastOrNull;

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

    final outputFile = File(
      p.join(
        "posts",
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
