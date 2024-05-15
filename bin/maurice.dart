import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';

import 'commands/create_command.dart';
import 'commands/post_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner("maurice", "Generate static website with Dart")
    ..addCommand(CreateCommand())
    ..addCommand(PostCommand());

  try {
    await runner.run(arguments);
  } on ArgumentError catch (ex) {
    PrintMessage.error(ex.message);
  }
}
