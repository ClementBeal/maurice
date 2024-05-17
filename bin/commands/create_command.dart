import 'dart:io';
import 'package:maurice/maurice.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

/// The "create" command creates a new Maurice project
/// It copies the "templates/project" folder into the given path
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

    final templatesFolder = Directory(getTemplatePath("project"));

    final directory = Directory(directoryPath);
    directory.createSync(recursive: true);

    // copy the folder recursivaly
    templatesFolder.listSync(recursive: true).forEach(
      (element) {
        final rest = element.path.split("templates/project/").last;
        if (element is Directory) {
          Directory(p.join(directory.path, rest)).createSync();
        } else if (element is File) {
          element.copySync(p.join(directory.path, rest));
        }
      },
    );
  }
}
