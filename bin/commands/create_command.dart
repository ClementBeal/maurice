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

    final directory = Directory(directoryPath);
    directory.createSync(recursive: true);

    File(p.join(directoryPath, "README.md")).createSync();
    File("bin/templates/_maurice.json")
        .copy(p.join(directoryPath, "maurice.json"));
    generateLayoutFolder(directoryPath);
    Directory(p.join(directoryPath, "posts")).createSync();
    Directory(p.join(directoryPath, "assets")).createSync();
  }

  void generateLayoutFolder(String directoryPath) {
    final d = Directory(p.join(directoryPath, "layouts"))..createSync();

    File("bin/templates/html/_base.html").copySync(p.join(d.path, "base.html"));
  }
}
