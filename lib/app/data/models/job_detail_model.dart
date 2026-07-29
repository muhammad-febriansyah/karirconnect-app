import 'job_model.dart';

/// `GET api/v1/jobs/{slug}`.
///
/// `JobDetailResource` extends `JobResource`, so [job] carries the same salary
/// and anonymity masking; the extra fields live alongside it rather than being
/// flattened, so nothing can bypass that masking by reading a raw column.
class JobDetailModel {
  const JobDetailModel({
    required this.job,
    required this.screeningQuestions,
    required this.similarJobs,
    this.description,
    this.responsibilities,
    this.requirements,
    this.benefits,
    this.minEducation,
    this.province,
    this.companyAbout,
    this.viewsCount,
    this.applicationsCount,
    this.isSaved,
    this.matchScore,
    this.hasApplied,
  });

  final JobModel job;

  final String? description;
  final String? responsibilities;
  final String? requirements;
  final String? benefits;
  final String? minEducation;
  final String? province;
  final String? companyAbout;
  final int? viewsCount;
  final int? applicationsCount;

  final List<ScreeningQuestion> screeningQuestions;

  /// From `meta.similar` — four more postings in the same category.
  final List<JobModel> similarJobs;

  /// Viewer-specific extras, present only when the request carried a token.
  /// The server puts these under `meta`, not `data`.
  final bool? isSaved;
  final num? matchScore;
  final bool? hasApplied;

  factory JobDetailModel.fromResponse(Map<String, dynamic> response) {
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return JobDetailModel(
      job: JobModel.fromJson(data),
      description: data['description'] as String?,
      responsibilities: data['responsibilities'] as String?,
      requirements: data['requirements'] as String?,
      benefits: data['benefits'] as String?,
      minEducation: data['min_education'] as String?,
      province: data['province'] as String?,
      companyAbout: data['company_about'] as String?,
      viewsCount: (data['views_count'] as num?)?.toInt(),
      applicationsCount: (data['applications_count'] as num?)?.toInt(),
      screeningQuestions: (data['screening_questions'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => ScreeningQuestion.fromJson(row.cast<String, dynamic>()))
          .toList(),
      similarJobs: (meta['similar'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => JobModel.fromJson(row.cast<String, dynamic>()))
          .toList(),
      isSaved: meta['is_saved'] as bool?,
      matchScore: meta['match_score'] as num?,
      hasApplied: meta['has_applied'] as bool?,
    );
  }
}

class ScreeningQuestion {
  const ScreeningQuestion({
    required this.id,
    required this.question,
    required this.isRequired,
    required this.options,
    this.type,
  });

  final int id;
  final String question;

  /// `text`, `number`, `yes_no`, `single_choice` or `multi_choice`.
  final String? type;

  final bool isRequired;

  /// Null for the non-choice types — those have nothing to pick from.
  final List<String> options;

  bool get isChoice => type == 'single_choice' || type == 'multi_choice';
  bool get isMultiChoice => type == 'multi_choice';
  bool get isYesNo => type == 'yes_no';
  bool get isNumber => type == 'number';

  factory ScreeningQuestion.fromJson(Map<String, dynamic> json) =>
      ScreeningQuestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        question: json['question'] as String? ?? '',
        type: json['type'] as String?,
        isRequired: json['is_required'] as bool? ?? false,
        options: (json['options'] as List? ?? const [])
            .map((option) => option.toString())
            .toList(),
      );
}
