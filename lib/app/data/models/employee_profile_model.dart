/// One entry of `meta.missing_items` on `GET api/v1/profile`.
///
/// `EmployeeProfileService::missingItems()` returns objects, not strings —
/// `{key, label, href}` — so this must be parsed rather than stringified.
/// `href` points at a web route and has no mobile screen behind it yet.
class ProfileMissingItem {
  const ProfileMissingItem({
    required this.key,
    required this.label,
    this.href,
  });

  final String key;
  final String label;
  final String? href;

  factory ProfileMissingItem.fromJson(Map<String, dynamic> json) =>
      ProfileMissingItem(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        href: json['href'] as String?,
      );
}

/// Mirrors `App\Http\Resources\Api\V1\EmployeeProfileResource`.
///
/// Only the fields the profile tab renders are parsed; the nested education /
/// work-experience / certification lists arrive as `whenLoaded` arrays and are
/// kept raw until a screen needs them.
class EmployeeProfileModel {
  const EmployeeProfileModel({
    required this.id,
    required this.profileCompletion,
    required this.isOpenToWork,
    required this.skills,
    required this.educationCount,
    required this.workExperienceCount,
    required this.certificationCount,
    this.headline,
    this.about,
    this.city,
    this.province,
    this.currentPosition,
    this.experienceLevel,
    this.expectedSalaryMin,
    this.expectedSalaryMax,
    this.gender,
    this.dateOfBirth,
    this.provinceId,
    this.cityId,
    this.portfolioUrl,
    this.linkedinUrl,
    this.githubUrl,
    this.visibility,
  });

  final int id;
  final String? headline;
  final String? about;
  final String? city;
  final String? province;
  final String? currentPosition;
  final String? experienceLevel;
  final int? expectedSalaryMin;
  final int? expectedSalaryMax;

  // These round-trip through `POST api/v1/profile`. The edit form must load
  // every one of them: the update request replaces the whole record, so a field
  // the form never read is a field the next save silently clears.
  final String? gender;
  final String? dateOfBirth;
  final int? provinceId;
  final int? cityId;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String? githubUrl;

  /// `public`, `recruiter_only` or `private`.
  final String? visibility;

  /// 0–100, computed server-side. Applying requires at least 60.
  final int profileCompletion;

  final bool isOpenToWork;
  final List<String> skills;
  final int educationCount;
  final int workExperienceCount;
  final int certificationCount;

  /// `SubmitApplicationAction` rejects an application below this threshold.
  bool get canApply => profileCompletion >= 60;

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) =>
      EmployeeProfileModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        headline: json['headline'] as String?,
        about: json['about'] as String?,
        city: json['city'] as String?,
        province: json['province'] as String?,
        currentPosition: json['current_position'] as String?,
        experienceLevel: json['experience_level'] as String?,
        expectedSalaryMin: (json['expected_salary_min'] as num?)?.toInt(),
        expectedSalaryMax: (json['expected_salary_max'] as num?)?.toInt(),
        gender: json['gender'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        provinceId: (json['province_id'] as num?)?.toInt(),
        cityId: (json['city_id'] as num?)?.toInt(),
        portfolioUrl: json['portfolio_url'] as String?,
        linkedinUrl: json['linkedin_url'] as String?,
        githubUrl: json['github_url'] as String?,
        visibility: json['visibility'] as String?,
        profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 0,
        isOpenToWork: json['is_open_to_work'] as bool? ?? false,
        skills: (json['skills'] as List? ?? const [])
            .whereType<Map>()
            .map((skill) => skill['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList(),
        educationCount: (json['educations'] as List?)?.length ?? 0,
        workExperienceCount: (json['work_experiences'] as List?)?.length ?? 0,
        certificationCount: (json['certifications'] as List?)?.length ?? 0,
      );
}
