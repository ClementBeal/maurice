import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Get a path relative to the templates folder
String getTemplatePath(String path) {
  final libFolder = Isolate.resolvePackageUriSync(
    Uri.parse('package:maurice/maurice.dart'),
  );

  return p.join(p.dirname(libFolder!.path), "templates", path);
}
