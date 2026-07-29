/// `GET api/v1/job-alerts` — hand-built payload, not a resource class, and
/// unpaginated (the controller returns the whole list under `data`).
class JobAlertModel {
  const JobAlertModel({
    required this.id,
    required this.name,
    required this.frequency,
    required this.isActive,
    required this.totalMatchesSent,
    this.keyword,
    this.jobCategoryId,
    this.category,
    this.cityId,
    this.city,
    this.provinceId,
    this.experienceLevel,
    this.employmentType,
    this.workArrangement,
    this.salaryMin,
    this.lastSentAt,
  });

  final int id;
  final String name;
  final String? keyword;
  final int? jobCategoryId;
  final String? category;
  final int? cityId;
  final String? city;
  final int? provinceId;
  final String? experienceLevel;
  final String? employmentType;
  final String? workArrangement;
  final int? salaryMin;

  /// `instant`, `daily` or `weekly`.
  final String frequency;

  final bool isActive;
  final String? lastSentAt;
  final int totalMatchesSent;

  factory JobAlertModel.fromJson(Map<String, dynamic> json) => JobAlertModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        keyword: json['keyword'] as String?,
        jobCategoryId: (json['job_category_id'] as num?)?.toInt(),
        category: json['category'] as String?,
        cityId: (json['city_id'] as num?)?.toInt(),
        city: json['city'] as String?,
        provinceId: (json['province_id'] as num?)?.toInt(),
        experienceLevel: json['experience_level'] as String?,
        employmentType: json['employment_type'] as String?,
        workArrangement: json['work_arrangement'] as String?,
        salaryMin: (json['salary_min'] as num?)?.toInt(),
        frequency: json['frequency'] as String? ?? 'daily',
        isActive: json['is_active'] as bool? ?? true,
        lastSentAt: json['last_sent_at'] as String?,
        totalMatchesSent: (json['total_matches_sent'] as num?)?.toInt() ?? 0,
      );

  /// Shaped for `POST` / `PUT api/v1/job-alerts`.
  ///
  /// `name` and `frequency` are required server-side; every other key is
  /// nullable and omitted rather than sent as null so a partial edit does not
  /// trip the `exists:` rules with a stale id.
  Map<String, dynamic> toPayload() => {
        'name': name,
        'frequency': frequency,
        'is_active': isActive,
        'keyword': ?keyword,
        'job_category_id': ?jobCategoryId,
        'city_id': ?cityId,
        'province_id': ?provinceId,
        'experience_level': ?experienceLevel,
        'employment_type': ?employmentType,
        'work_arrangement': ?workArrangement,
        'salary_min': ?salaryMin,
      };

  JobAlertModel copyWith({
    String? name,
    String? frequency,
    bool? isActive,
    String? keyword,
    int? jobCategoryId,
    int? provinceId,
    String? experienceLevel,
    String? employmentType,
    String? workArrangement,
    int? salaryMin,
    bool clearKeyword = false,
    bool clearCategory = false,
    bool clearProvince = false,
    bool clearExperience = false,
    bool clearEmployment = false,
    bool clearArrangement = false,
    bool clearSalary = false,
  }) =>
      JobAlertModel(
        id: id,
        name: name ?? this.name,
        frequency: frequency ?? this.frequency,
        isActive: isActive ?? this.isActive,
        totalMatchesSent: totalMatchesSent,
        keyword: clearKeyword ? null : (keyword ?? this.keyword),
        jobCategoryId:
            clearCategory ? null : (jobCategoryId ?? this.jobCategoryId),
        category: clearCategory ? null : category,
        cityId: cityId,
        city: city,
        provinceId: clearProvince ? null : (provinceId ?? this.provinceId),
        experienceLevel:
            clearExperience ? null : (experienceLevel ?? this.experienceLevel),
        employmentType:
            clearEmployment ? null : (employmentType ?? this.employmentType),
        workArrangement:
            clearArrangement ? null : (workArrangement ?? this.workArrangement),
        salaryMin: clearSalary ? null : (salaryMin ?? this.salaryMin),
        lastSentAt: lastSentAt,
      );
}
