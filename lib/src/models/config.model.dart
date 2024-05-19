import 'dart:convert';
import 'dart:io';

import 'package:maurice/maurice.dart';

/// A representation of the Maurice's configuraiton
class Config {
  /// the baseurl of the website (eg: https://my-blog.com)
  final String baseurl;

  /// the title of the RSS channel
  final String rssChannelTitle;

  /// the description of the RSS channel
  final String rssChanneldescription;

  Config({
    required this.baseurl,
    required this.rssChannelTitle,
    required this.rssChanneldescription,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      baseurl: json["baseurl"],
      rssChannelTitle: json["rssChannelTitle"],
      rssChanneldescription: json["rssChannelDescription"],
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
