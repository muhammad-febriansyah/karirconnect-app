/// One row of `GET api/v1/career-resources`.
///
/// The controller hand-builds this payload rather than going through a
/// resource class, and it reports `created_at` under the `published_at` key.
class CareerResourceModel {
  const CareerResourceModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.tags,
    this.excerpt,
    this.category,
    this.thumbnailUrl,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? category;
  final List<String> tags;
  final String? thumbnailUrl;
  final String? publishedAt;

  factory CareerResourceModel.fromJson(Map<String, dynamic> json) =>
      CareerResourceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        excerpt: json['excerpt'] as String?,
        category: json['category'] as String?,
        // `tags` is a JSON column, so it can arrive as a list or as null.
        tags: (json['tags'] as List? ?? const [])
            .map((tag) => tag.toString())
            .toList(),
        thumbnailUrl: json['thumbnail_url'] as String?,
        publishedAt: json['published_at'] as String?,
      );
}

/// `GET api/v1/career-resources/{slug}` — the list row plus the article body.
class CareerResourceDetailModel {
  const CareerResourceDetailModel({
    required this.resource,
    this.body,
    this.author,
  });

  final CareerResourceModel resource;

  /// Rich text from the admin editor.
  final String? body;

  final String? author;

  factory CareerResourceDetailModel.fromJson(Map<String, dynamic> json) =>
      CareerResourceDetailModel(
        resource: CareerResourceModel.fromJson(json),
        body: json['body'] as String?,
        author: json['author'] as String?,
      );
}
