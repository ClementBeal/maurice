import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:markdown/markdown.dart';
import 'package:maurice/maurice.dart';
import 'package:maurice/src/utils/file_parser.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import 'package:slugify/slugify.dart';
import 'package:xml/xml.dart';

class BuildCommand extends Command {
  @override
  final name = "build";
  @override
  final description = "Build the project into html files";

  late String baseHtml;
  late String outputPath;
  late Template baseTemplate;

  BuildCommand();

  /// Prepare the build environment
  /// We load the base template, clean the output folder and that's it
  void _load() {
    baseHtml = File("layouts/_base.html").readAsStringSync();

    Directory("output")
      ..deleteSync(recursive: true)
      ..createSync();
    outputPath = "output";

    baseTemplate =
        Template(baseHtml, name: "_base.html", htmlEscapeValues: false);
  }

  @override
  void run() {
    if (argResults == null) {
      return;
    }

    _load();

    final sitemap = _buildPages();
    _buildAssets();

    _generateSitemap(sitemap);
  }

  /// Copy the assets folder to the output
  /// TODO : check if the images can be converted to be a better format(webp)
  void _buildAssets() {
    final templatesFolder = Directory("assets");
    Directory(p.join(outputPath, "assets")).createSync();

    templatesFolder.listSync(recursive: true).forEach(
      (element) {
        final rest = element.path.split("assets/").last;
        if (element is Directory) {
          Directory(p.join(outputPath, "assets", rest)).createSync();
        } else if (element is File) {
          element.copySync(p.join(outputPath, "assets", rest));
        }
      },
    );
  }

  /// Generates the pages and subpages
  ///
  /// We generate different kind of pages:
  ///
  /// - standalone page : they don't use resources
  ///
  /// - resource page : they use a resource to generate its content
  ///
  /// - paginated resource page : take all the resources needed by the page and generate X pages with X resources each
  ///
  /// - unique-resource page : generate one page per item of the resource
  List<SitemapItem> _buildPages() {
    final sitemap = <SitemapItem>[];
    final pagesFiles = Directory("pages").listSync().whereType<File>().where(
          (e) => p.extension(e.path) == ".html",
        );

    for (var page in pagesFiles) {
      final filename = p.basename(page.path);
      final data = parseFile(page);

      if (data == null) {
        PrintMessage.error(
            "The following page is incorrect : ${page.absolute.path}");
        exit(0);
      }

      if (data.arguments["use_resource"] != null) {
        // get the HTML block of the HTML file and put it into the template
        final htmlTemplate = Template(
          data.markdown,
          name: page.path,
          htmlEscapeValues: false,
        );

        // the name of the resource to inject
        final String resource = data.arguments["use_resource"];

        // gather all the resources of this type
        final resourceFiles = Directory(p.join("resources", resource))
            .listSync()
            .whereType<Directory>()
            .map(
              (e) => File(
                p.join(
                  e.path,
                  p.setExtension(p.basenameWithoutExtension(e.path), ".md"),
                ),
              ),
            );

        final bool generateMultiplePages =
            data.arguments["one_page_per_item"] == "true";

        if (generateMultiplePages) {
          final String route = data.arguments["route"];
          final resourceOutputFolder = Directory(p.join(outputPath, route))
            ..createSync();

          // for each resource file, we generate one page
          for (var resourceFile in resourceFiles) {
            final data = parseFile(resourceFile.absolute);
            final filename = p.join(
                resourceOutputFolder.path, slugify(data!.arguments["title"]));

            sitemap.add(
              SitemapItem(
                url:
                    "https://test.com/$route${slugify(data.arguments["title"])}",
              ),
            );

            final pageContent = baseTemplate.renderString(
              {
                "page": {
                  "title": "",
                  "description": "",
                },
                ...data.arguments,
                "body": markdownToHtml(data.markdown),
              },
            );

            _saveHTMLpage(File(p.setExtension(filename, ".html")), pageContent);
          }
        } else if (data.arguments["use_pagination"] == "true") {
          final data = <FileContent>[];

          for (var e in resourceFiles) {
            final fileData = parseFile(e);

            if (fileData != null) {
              data.add(fileData);
            }
          }

          final a = htmlTemplate.renderString({
            "${resource}s": data.map(
              (e) => e.arguments,
            )
          });

          final htmlContent = baseTemplate.renderString(
            {
              "body": a,
              "page": {
                "title": "",
                "description": "",
              }
            },
          );

          _saveHTMLpage(
            File(p.join(outputPath, "${resource}s", "page", "1.html")),
            htmlContent,
          );
        } else {
          final data = <FileContent>[];

          for (var e in resourceFiles) {
            final fileData = parseFile(e);

            if (fileData != null) {
              data.add(fileData);
            }
          }

          final htmlContent = htmlTemplate.renderString({
            "${resource}s": data.map(
              (e) => e.arguments,
            )
          });

          _saveHTMLpage(File(p.join(outputPath, filename)), htmlContent);
        }
      } else {
        final output = baseTemplate.renderString(
          {
            "body": data.markdown,
            "page": {
              "title": data.arguments["title"],
              "description": data.arguments["description"],
            }
          },
        );

        sitemap.add(SitemapItem(url: "https://test.com/$filename"));

        _saveHTMLpage(File(p.join(outputPath, filename)), output);
      }
    }

    return sitemap;
  }

  /// Generate the sitemap using the previously generated pages
  void _generateSitemap(List<SitemapItem> urls) {
    final builder = XmlBuilder();
    builder.processing("xml", "version='1.0' encoding='UTF-8'");
    builder.element("urlset", attributes: {
      "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation":
          "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
      "xmlns": "http://www.sitemaps.org/schemas/sitemap/0.9",
    }, nest: () {
      for (var item in urls) {
        builder.element("url", nest: () {
          builder.element("loc", nest: () {
            builder.text(item.url);
          });
          builder.element("changefreq", nest: () {
            builder.text("monthly");
          });
          builder.element("priority", nest: () {
            builder.text("0.5");
          });
        });
      }
    });

    File(p.join(outputPath, "sitemap.xml"))
        .writeAsStringSync(builder.buildDocument().outerXml);
  }

  /// Minify the HTML code and save it into a file
  void _saveHTMLpage(File htmlFile, String htmlContent) {
    final minifiedHTML = XmlDocument.parse(htmlContent).outerXml;

    htmlFile.parent.createSync(recursive: true);
    htmlFile.writeAsStringSync(minifiedHTML);
  }
}

class SitemapItem {
  final String url;

  SitemapItem({required this.url});
}
