import 'package:args/command_runner.dart';
import 'package:maurice/maurice.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner("maurice", "Generate static website with Dart")
    ..addCommand(CreateCommand())
    ..addCommand(BuildCommand())
    ..addCommand(PageCommand())
    ..addCommand(ResourceCommand());

  try {
    await runner.run(arguments);
  } on ArgumentError catch (ex) {
    PrintMessage.error(ex.message);
  }
}
