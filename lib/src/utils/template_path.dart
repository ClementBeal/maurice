import 'dart:io';
import 'package:path/path.dart' as p;

String getTemplatePath(String path) {
  return p.join(File(Platform.script.path).parent.path, "templates", path);
}
