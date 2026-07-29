/// Mirrors `App\Http\Resources\Api\V1\CompanyResource`.
///
/// `open_jobs_count` is only present on the index endpoint, which adds it via
/// `withCount`. The detail endpoint omits the key entirely.
class CompanyModel {
  const CompanyModel({
    required this.id,
    required this.name,
    required this.slug,
    this.tagline,
    this.industry,
    this.city,
    this.size,
    this.logoUrl,
    this.verificationStatus,
    this.openJobsCount,
  });

  final int id;
  final String name;
  final String slug;
  final String? tagline;
  final String? industry;
  final String? city;
  final String? size;
  final String? logoUrl;
  final String? verificationStatus;
  final int? openJobsCount;

  bool get isVerified => verificationStatus == 'verified';

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '-',
        slug: json['slug'] as String? ?? '',
        tagline: json['tagline'] as String?,
        industry: json['industry'] as String?,
        city: json['city'] as String?,
        size: json['size'] as String?,
        logoUrl: json['logo_url'] as String?,
        verificationStatus: json['verification_status'] as String?,
        openJobsCount: (json['open_jobs_count'] as num?)?.toInt(),
      );
}
