import 'package:args/command_runner.dart';
import '../utils/interactions.dart';

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

    PostModel
  }
}
