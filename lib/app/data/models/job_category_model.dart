/// One entry of `data.job_categories` from `GET api/v1/meta`.
///
/// The meta endpoint does not carry a per-category job count — the web landing
/// gets that from `HomeService::topCategories()`, which has no API equivalent.
class JobCategoryModel {
  const JobCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory JobCategoryModel.fromJson(Map<String, dynamic> json) =>
      JobCategoryModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
      );
}
