import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

class CreateCommand extends Command {
  @override
  final name = "create";
  @override
  final description = "Create a new Maurice project";

  CreateCommand();

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    final directoryPath = argResults!.rest.first;

    final templatesFolder = Directory(
        p.join(File(Platform.script.path).parent.path, "templates", "project"));

    final directory = Directory(directoryPath);
    directory.createSync(recursive: true);

    templatesFolder.listSync(recursive: true).forEach(
      (element) {
        final rest = element.path.split("templates/project/").last;
        print(rest);
        if (element is Directory) {
          Directory(p.join(directory.path, rest)).createSync();
        } else if (element is File) {
          element.copySync(p.join(directory.path, rest));
        }
      },
    );
  }
}
