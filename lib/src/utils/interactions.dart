import 'dart:io';

import 'print_messages.dart';

/// Ask a question to the user and get its answer
/// The possible answers are yes/y/no/n
bool askChoiceQuestion(String question) {
  String? answer;

  while (!["yes", "no", "y", "n"].contains(answer)) {
    answer = askQuestion("$question (y/n)");
  }

  return ["yes", "y"].contains(answer);
}

/// Ask a question to the user and get its answer
String askQuestion(String question) {
  PrintMessage.question("$question ");
  return stdin.readLineSync() ?? "";
}

/// Ask a question to the user and get its answer
/// Only possible answers are integers
int askNumericQuestion(String question) {
  String? answer;

  while (int.tryParse(answer ?? "") == null) {
    answer = askQuestion(question);

    if (int.tryParse(answer) == null) {
      PrintMessage.error("Enter an integer");
    }
  }

  return int.parse(answer!);
}
