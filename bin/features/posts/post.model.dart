class PostModel {
  final DateTime creationDate;
  final String title;

  PostModel({required this.creationDate, required this.title});

  PostModel fromJson(Map<String, dynamic> json) => PostModel(
        creationDate: DateTime.parse(json["creationDate"]),
        title: json["title"],
      );

  Map<String, dynamic> toJson() {
    return {"title": title, "creationDate": creationDate};
  }
}
