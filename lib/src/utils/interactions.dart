import 'dart:io';

import 'print_messages.dart';

bool askChoiceQuestion(String question) {
  String? answer;

  while (!["yes", "no", "y", "n"].contains(answer)) {
    PrintMessage.question("$question (y/n)");
    answer = stdin.readLineSync();
  }

  return ["yes", "y"].contains(answer);
}

String askQuestion(String question) {
  PrintMessage.question("$question: ");
  return stdin.readLineSync() ?? "";
}

int askNumericQuestion(String question) {
  String? answer;

  while (int.tryParse(answer ?? "") == null) {
    PrintMessage.question("$question: ");
    answer = stdin.readLineSync();

    if (int.tryParse(answer ?? "") == null) {
      PrintMessage.error("Enter an integer");
    }
  }

  return int.parse(answer!);
}
