import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart';
import 'package:maurice/maurice.dart';
import 'package:maurice/src/models/config.model.dart';
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

    final outputDirectory = Directory("output");
    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }

    outputDirectory.createSync();
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

    final result = _buildPages();
    _buildAssets();

    _generateSitemap(result.$1);
    _generateRSSFeed(Config.fromConfigFile(), result.$2);
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
  (List<SitemapItem>, List<RSSItem>) _buildPages() {
    final config = Config.fromConfigFile();

    final workingDirectory = p.join(Directory.current.path, "pages");

    final sitemap = <SitemapItem>[];
    final rss = <RSSItem>[];

    final pagesFiles =
        Directory("pages").listSync(recursive: true).whereType<File>().where(
              (e) => p.extension(e.path) == ".html",
            );

    for (var page in pagesFiles) {
      // extract the relative folder
      final route =
          File(p.relative(page.absolute.path, from: workingDirectory));

      // bad name
      // it's the route folder (eg: a/b/c/articles)
      final parent = Directory(p.join(outputPath, route.parent.path));
      print(parent.absolute.path);
      parent.createSync(recursive: true);

      final filename = p.basename(route.path);
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
          // for each resource file, we generate one page
          final pageItemTemplate =
              Template(page.readAsStringSync(), htmlEscapeValues: false);

          // it must have a title variable for the filename
          for (var resourceFile in resourceFiles) {
            final data = parseFile(resourceFile.absolute);
            if (!data!.arguments.containsKey("published")) {
              continue;
            }
            final filename =
                p.join(parent.path, slugify(data.arguments["title"]));

            sitemap.add(
              SitemapItem.url(
                config.baseurl,
                "${route.parent.path}/${slugify(data.arguments["title"])}",
              ),
            );
            rss.add(
              RSSItem.url(
                data.arguments["title"] ?? "",
                data.arguments["description"] ?? "",
                config.baseurl,
                DateTime.parse(data.arguments["published"]),
                "${route.parent.path}/${slugify(data.arguments["title"])}",
              ),
            );

            final pageItemContent = pageItemTemplate.renderString({
              ...data.arguments,
              "body": markdownToHtml(data.markdown),
            });

            final itemData = parseContent(pageItemContent.split("\n"))!;
            final pageContent = baseTemplate.renderString(
              {
                ...itemData.arguments,
                "body": itemData.markdown,
              },
            );

            _saveHTMLpage(File(p.setExtension(filename, ".html")), pageContent);
          }
        } else if (data.arguments["use_pagination"] == "true") {
          final fileContents = <FileContent>[];
          final itemsPerPage = int.parse(data.arguments["items_per_page"]!);

          for (var e in resourceFiles) {
            final fileData = parseFile(e);

            if (fileData != null) {
              fileContents.add(fileData);
            }
          }

          int i = 0;

          while (i < fileContents.length) {
            final itemPage = fileContents.skip(i).take(itemsPerPage);
            i += itemsPerPage;

            final a = htmlTemplate.renderString({
              "${resource}s": itemPage.map(
                (e) => e.arguments,
              )
            });

            final htmlContent = baseTemplate.renderString(
              {
                "body": a,
                "_pageTitle": "",
                "_pageDescription": "",
              },
            );

            final pageId = i ~/ itemsPerPage;

            if (pageId == 1) {
              _saveHTMLpage(
                File(p.join(parent.path, "index.html")),
                htmlContent,
              );
            }

            _saveHTMLpage(
              File(p.join(outputPath, "${resource}s", "page", "$pageId.html")),
              htmlContent,
            );
          }
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
            "_pageTitle": data.arguments["_pageTitle"] ?? "",
            "_pageDescription": data.arguments["_pageDescription"] ?? "",
          },
        );

        sitemap.add(SitemapItem.url(config.baseurl, filename));
        _saveHTMLpage(
            File(
              p.join((parent.path == ".") ? "" : parent.path, filename),
            ),
            output);
      }
    }

    return (sitemap, rss);
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

  /// Generate the RSS feed using the previously generated pages
  void _generateRSSFeed(Config config, List<RSSItem> urls) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss');

    final builder = XmlBuilder();

    builder.processing("rss", "version='2.0'");
    builder.element(
      "channel",
      nest: () {
        builder.element("title", nest: () {
          builder.text("No title for the channel");
        });
        builder.element("link", nest: () {
          builder.text("${config.baseurl}/rss.xml");
        });

        builder.element("description", nest: () {
          builder.text("No description for the channel");
        });

        for (var url in urls) {
          builder.element(
            "item",
            nest: () {
              builder.element("title", nest: () {
                builder.text(url.title);
              });
              builder.element("link", nest: () {
                builder.text(url.url);
              });
              builder.element("description", nest: () {
                builder.text(url.description);
              });
              builder.element("pubDate", nest: () {
                builder.text(dateFormat.format(url.publishedDate));
              });
            },
          );
        }
      },
    );

    File(p.join(outputPath, "rss.xml"))
        .writeAsStringSync(builder.buildDocument().outerXml);
  }

  /// Minify the HTML code and save it into a file
  void _saveHTMLpage(File htmlFile, String htmlContent) {
    final xmlFile = XmlDocument.parse(htmlContent)
      ..normalize(trimAllWhitespace: true);

    final minifiedHTML = xmlFile.outerXml;

    htmlFile.parent.createSync(recursive: true);
    htmlFile.writeAsStringSync(minifiedHTML);
  }
}

class SitemapItem {
  final String url;

  SitemapItem({required this.url});

  factory SitemapItem.url(String url, String path) {
    if (url.startsWith("https")) {
      return SitemapItem(
        url: Uri.https(url.split("https://").last, path).toString(),
      );
    } else {
      return SitemapItem(
        url: Uri.http(url.split("http://").last, path).toString(),
      );
    }
  }
}

class RSSItem {
  final String title;
  final String url;
  final DateTime publishedDate;
  final String description;

  RSSItem({
    required this.title,
    required this.url,
    required this.publishedDate,
    required this.description,
  });

  factory RSSItem.url(
    String title,
    String description,
    String url,
    DateTime publishedData,
    String path,
  ) {
    if (url.startsWith("https")) {
      return RSSItem(
        title: title,
        description: description,
        publishedDate: publishedData,
        url: Uri.https(url.split("https://").last, path).toString(),
      );
    } else {
      return RSSItem(
        title: title,
        description: description,
        publishedDate: publishedData,
        url: Uri.http(url.split("http://").last, path).toString(),
      );
    }
  }
}
