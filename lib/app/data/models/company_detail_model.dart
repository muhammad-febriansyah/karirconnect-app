import 'company_model.dart';

/// `GET api/v1/companies/{slug}`.
///
/// `CompanyDetailResource` extends `CompanyResource`, so [company] holds the
/// shared fields. `open_jobs_count` is **not** among them — the detail endpoint
/// does not `withCount`, so it is always null here.
class CompanyDetailModel {
  const CompanyDetailModel({
    required this.company,
    required this.offices,
    required this.badges,
    this.about,
    this.culture,
    this.benefits,
    this.website,
    this.province,
    this.coverUrl,
    this.foundedYear,
  });

  final CompanyModel company;

  final String? about;
  final String? culture;
  final String? benefits;
  final String? website;
  final String? province;
  final String? coverUrl;
  final int? foundedYear;

  final List<CompanyOffice> offices;
  final List<CompanyBadge> badges;

  factory CompanyDetailModel.fromJson(Map<String, dynamic> json) =>
      CompanyDetailModel(
        company: CompanyModel.fromJson(json),
        about: json['about'] as String?,
        culture: json['culture'] as String?,
        benefits: json['benefits'] as String?,
        website: json['website'] as String?,
        province: json['province'] as String?,
        coverUrl: json['cover_url'] as String?,
        foundedYear: (json['founded_year'] as num?)?.toInt(),
        offices: (json['offices'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => CompanyOffice.fromJson(row.cast<String, dynamic>()))
            .toList(),
        badges: (json['badges'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => CompanyBadge.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
}

class CompanyOffice {
  const CompanyOffice({
    required this.id,
    required this.isHeadquarter,
    this.label,
    this.address,
    this.mapUrl,
  });

  final int id;
  final String? label;
  final String? address;
  final bool isHeadquarter;
  final String? mapUrl;

  factory CompanyOffice.fromJson(Map<String, dynamic> json) => CompanyOffice(
        id: (json['id'] as num?)?.toInt() ?? 0,
        label: json['label'] as String?,
        address: json['address'] as String?,
        isHeadquarter: json['is_headquarter'] as bool? ?? false,
        mapUrl: json['map_url'] as String?,
      );
}

class CompanyBadge {
  const CompanyBadge({required this.id, required this.name, this.tone});

  final int id;
  final String name;
  final String? tone;

  factory CompanyBadge.fromJson(Map<String, dynamic> json) => CompanyBadge(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        tone: json['tone'] as String?,
      );
}

/// One row of `GET api/v1/companies/{slug}/reviews`.
class CompanyReviewModel {
  const CompanyReviewModel({
    required this.id,
    required this.rating,
    required this.isAnonymous,
    required this.wouldRecommend,
    required this.helpfulCount,
    this.title,
    this.pros,
    this.cons,
    this.jobTitle,
    this.employmentStatus,
    this.authorName,
    this.responseBody,
    this.createdAt,
  });

  final int id;
  final String? title;
  final num rating;
  final String? pros;
  final String? cons;
  final String? jobTitle;
  final String? employmentStatus;
  final bool wouldRecommend;
  final bool isAnonymous;

  /// Null when the author chose to stay anonymous — the API withholds both the
  /// name and the avatar in that case.
  final String? authorName;

  /// The employer's public reply, when there is one.
  final String? responseBody;

  final int helpfulCount;
  final String? createdAt;

  String get displayName => authorName ?? 'Anonim';

  factory CompanyReviewModel.fromJson(Map<String, dynamic> json) =>
      CompanyReviewModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        rating: (json['rating'] as num?) ?? 0,
        pros: json['pros'] as String?,
        cons: json['cons'] as String?,
        jobTitle: json['job_title'] as String?,
        employmentStatus: json['employment_status'] as String?,
        wouldRecommend: json['would_recommend'] as bool? ?? false,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        authorName: json['author_name'] as String?,
        responseBody: json['response_body'] as String?,
        helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String?,
      );
}
