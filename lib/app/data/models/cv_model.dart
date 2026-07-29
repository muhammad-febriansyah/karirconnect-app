/// One row of `GET api/v1/cvs`.
class CandidateCvModel {
  const CandidateCvModel({
    required this.id,
    required this.label,
    required this.isActive,
    this.source,
    this.pagesCount,
    this.fileUrl,
    this.createdAt,
  });

  final int id;
  final String label;

  /// `upload` for a file the candidate uploaded, `builder` for a generated one.
  final String? source;

  /// Whether this CV is attached to new applications by default. The server
  /// keeps at most one active per profile.
  final bool isActive;

  final int? pagesCount;
  final String? fileUrl;
  final String? createdAt;

  bool get isGenerated => source == 'builder';

  factory CandidateCvModel.fromJson(Map<String, dynamic> json) =>
      CandidateCvModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? 'CV',
        source: json['source'] as String?,
        isActive: json['is_active'] as bool? ?? false,
        pagesCount: (json['pages_count'] as num?)?.toInt(),
        fileUrl: json['file_url'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

/// The saved builder draft from `GET api/v1/cv-builder`, so the form resumes
/// where the candidate left off. `draft` is null when nothing was built yet.
class CvBuilderDraft {
  const CvBuilderDraft({
    required this.personal,
    required this.experiences,
    required this.educations,
    required this.skills,
    required this.certifications,
    this.summary,
    this.primaryResumeId,
  });

  final CvBuilderPersonal personal;
  final String? summary;
  final List<CvBuilderExperience> experiences;
  final List<CvBuilderEducation> educations;
  final List<String> skills;
  final List<CvBuilderCertification> certifications;
  final int? primaryResumeId;

  static const CvBuilderDraft empty = CvBuilderDraft(
    personal: CvBuilderPersonal(fullName: ''),
    experiences: [],
    educations: [],
    skills: [],
    certifications: [],
  );

  factory CvBuilderDraft.fromResponse(Map<String, dynamic> response) {
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final draft = (data['draft'] as Map?)?.cast<String, dynamic>() ?? const {};

    return CvBuilderDraft(
      personal: CvBuilderPersonal.fromJson(
        (draft['personal'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      summary: draft['summary'] as String?,
      experiences: (draft['experiences'] as List? ?? const [])
          .whereType<Map>()
          .map((row) =>
              CvBuilderExperience.fromJson(row.cast<String, dynamic>()))
          .toList(),
      educations: (draft['educations'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => CvBuilderEducation.fromJson(row.cast<String, dynamic>()))
          .toList(),
      skills: (draft['skills'] as List? ?? const [])
          .map((skill) => skill.toString())
          .where((skill) => skill.isNotEmpty)
          .toList(),
      certifications: (draft['certifications'] as List? ?? const [])
          .whereType<Map>()
          .map((row) =>
              CvBuilderCertification.fromJson(row.cast<String, dynamic>()))
          .toList(),
      primaryResumeId: (data['primary_resume_id'] as num?)?.toInt(),
    );
  }
}

class CvBuilderPersonal {
  const CvBuilderPersonal({
    required this.fullName,
    this.headline,
    this.email,
    this.phone,
    this.location,
    this.website,
  });

  final String fullName;
  final String? headline;
  final String? email;
  final String? phone;
  final String? location;
  final String? website;

  factory CvBuilderPersonal.fromJson(Map<String, dynamic> json) =>
      CvBuilderPersonal(
        fullName: json['full_name'] as String? ?? '',
        headline: json['headline'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        location: json['location'] as String?,
        website: json['website'] as String?,
      );
}

/// The builder stores periods as free text (`"2020 – 2023"`), not dates —
/// unlike the profile's work experiences.
class CvBuilderExperience {
  const CvBuilderExperience({
    required this.company,
    required this.position,
    this.period,
    this.description,
  });

  final String company;
  final String position;
  final String? period;
  final String? description;

  factory CvBuilderExperience.fromJson(Map<String, dynamic> json) =>
      CvBuilderExperience(
        company: json['company'] as String? ?? '',
        position: json['position'] as String? ?? '',
        period: json['period'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'company': company,
        'position': position,
        'period': ?period,
        'description': ?description,
      };
}

class CvBuilderEducation {
  const CvBuilderEducation({
    required this.institution,
    this.major,
    this.period,
    this.gpa,
  });

  final String institution;
  final String? major;
  final String? period;

  /// A string here, not a number — the builder takes it verbatim.
  final String? gpa;

  factory CvBuilderEducation.fromJson(Map<String, dynamic> json) =>
      CvBuilderEducation(
        institution: json['institution'] as String? ?? '',
        major: json['major'] as String?,
        period: json['period'] as String?,
        gpa: json['gpa']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'major': ?major,
        'period': ?period,
        'gpa': ?gpa,
      };
}

class CvBuilderCertification {
  const CvBuilderCertification({required this.name, this.issuer, this.year});

  final String name;
  final String? issuer;
  final String? year;

  factory CvBuilderCertification.fromJson(Map<String, dynamic> json) =>
      CvBuilderCertification(
        name: json['name'] as String? ?? '',
        issuer: json['issuer'] as String?,
        year: json['year']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'issuer': ?issuer,
        'year': ?year,
      };
}
