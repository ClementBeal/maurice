import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';
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

    while (title.isEmpty) {
      title = askQuestion("Title of the post");
    }

    PostModel(creationDate: DateTime.now(), title: title);

    final filename = "1-${slugify(title)}.md";

    File(p.join(File(Platform.script.path).parent.path, "templates/_post.md"))
        .copySync(
      p.join(
        "posts",
        filename,
      ),
    );
  }
}
