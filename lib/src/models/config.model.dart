import 'dart:convert';
import 'dart:io';

import 'package:maurice/maurice.dart';

/// A representation of the Maurice's configuraiton
class Config {
  /// the baseurl of the website (eg: https://my-blog.com)
  final String baseurl;

  Config({required this.baseurl});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      baseurl: json["baseurl"],
    );
  }

  factory Config.fromConfigFile() {
    final configFile = File("maurice.json");

    if (!configFile.existsSync()) {
      PrintMessage.error(
          'The "maurice.json" configuration file can\'t be found');
      exit(0);
    }

    final json = jsonDecode(configFile.readAsStringSync());

    return Config.fromJson(json);
  }
}
