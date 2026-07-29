/// Mirrors `App\Http\Resources\Api\V1\JobResource`.
///
/// Two masking rules are enforced server-side and must be respected here:
/// salary is null unless [isSalaryVisible], and an anonymous posting reports
/// its company as `Confidential` with no id or slug.
class JobModel {
  const JobModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.isFeatured,
    required this.isAnonymous,
    required this.isSalaryVisible,
    required this.company,
    required this.skills,
    this.employmentType,
    this.workArrangement,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.publishedAt,
    this.applicationDeadline,
    this.category,
    this.city,
  });

  final int id;
  final String slug;
  final String title;
  final String? employmentType;
  final String? workArrangement;
  final String? experienceLevel;
  final bool isFeatured;
  final bool isAnonymous;
  final int? salaryMin;
  final int? salaryMax;
  final bool isSalaryVisible;
  final String? publishedAt;
  final String? applicationDeadline;
  final JobCompany company;
  final String? category;
  final String? city;
  final List<String> skills;

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        employmentType: json['employment_type'] as String?,
        workArrangement: json['work_arrangement'] as String?,
        experienceLevel: json['experience_level'] as String?,
        isFeatured: json['is_featured'] as bool? ?? false,
        isAnonymous: json['is_anonymous'] as bool? ?? false,
        salaryMin: (json['salary_min'] as num?)?.toInt(),
        salaryMax: (json['salary_max'] as num?)?.toInt(),
        isSalaryVisible: json['is_salary_visible'] as bool? ?? false,
        publishedAt: json['published_at'] as String?,
        applicationDeadline: json['application_deadline'] as String?,
        company: JobCompany.fromJson(
          (json['company'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        category: json['category'] as String?,
        city: json['city'] as String?,
        skills: (json['skills'] as List?)
                ?.map((skill) => skill.toString())
                .toList() ??
            const [],
      );
}

class JobCompany {
  const JobCompany({
    required this.name,
    this.id,
    this.slug,
    this.logoUrl,
    this.verificationStatus,
  });

  final int? id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String? verificationStatus;

  bool get isVerified => verificationStatus == 'verified';

  factory JobCompany.fromJson(Map<String, dynamic> json) => JobCompany(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String? ?? '-',
        slug: json['slug'] as String?,
        logoUrl: json['logo_url'] as String?,
        verificationStatus: json['verification_status'] as String?,
      );
}
