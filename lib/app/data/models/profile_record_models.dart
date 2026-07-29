// The three repeating blocks of an employee profile. Each has its own
// apiResource under api/v1/profile/* and its own validation rules, so they stay
// separate types rather than sharing one shape.

class EducationModel {
  const EducationModel({
    required this.id,
    required this.level,
    required this.institution,
    required this.startYear,
    this.major,
    this.gpa,
    this.endYear,
    this.description,
  });

  final int id;

  /// `EducationLevel` value: `sma`, `d3`, `d4`, `s1`, `s2`, `s3`, `other`.
  /// Validated as a plain `max:16` string server-side, not as the enum.
  final String level;

  final String institution;
  final String? major;
  final num? gpa;
  final int startYear;
  final int? endYear;
  final String? description;

  factory EducationModel.fromJson(Map<String, dynamic> json) => EducationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        level: json['level'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        major: json['major'] as String?,
        gpa: json['gpa'] is String
            ? num.tryParse(json['gpa'] as String)
            : json['gpa'] as num?,
        startYear: (json['start_year'] as num?)?.toInt() ?? 0,
        endYear: (json['end_year'] as num?)?.toInt(),
        description: json['description'] as String?,
      );
}

class WorkExperienceModel {
  const WorkExperienceModel({
    required this.id,
    required this.companyName,
    required this.position,
    required this.startDate,
    required this.isCurrent,
    this.employmentType,
    this.endDate,
    this.description,
  });

  final int id;
  final String companyName;
  final String position;
  final String? employmentType;

  /// `yyyy-MM-dd`.
  final String startDate;
  final String? endDate;

  final bool isCurrent;
  final String? description;

  factory WorkExperienceModel.fromJson(Map<String, dynamic> json) =>
      WorkExperienceModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        companyName: json['company_name'] as String? ?? '',
        position: json['position'] as String? ?? '',
        employmentType: json['employment_type'] as String?,
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String?,
        isCurrent: json['is_current'] as bool? ?? false,
        description: json['description'] as String?,
      );
}

class CertificationModel {
  const CertificationModel({
    required this.id,
    required this.name,
    required this.issuer,
    this.credentialId,
    this.credentialUrl,
    this.issuedDate,
    this.expiresDate,
  });

  final int id;
  final String name;
  final String issuer;
  final String? credentialId;
  final String? credentialUrl;
  final String? issuedDate;
  final String? expiresDate;

  factory CertificationModel.fromJson(Map<String, dynamic> json) =>
      CertificationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        credentialId: json['credential_id'] as String?,
        credentialUrl: json['credential_url'] as String?,
        issuedDate: json['issued_date'] as String?,
        expiresDate: json['expires_date'] as String?,
      );
}
