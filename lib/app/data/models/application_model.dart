/// Mirrors `App\Http\Resources\Api\V1\ApplicationResource`.
///
/// `job` is `whenLoaded`, so it is absent on any endpoint that does not eager
/// load the relation.
class ApplicationModel {
  const ApplicationModel({
    required this.id,
    this.status,
    this.statusLabel,
    this.aiMatchScore,
    this.currentStage,
    this.appliedAt,
    this.job,
  });

  final int id;
  final String? status;
  final String? statusLabel;
  final num? aiMatchScore;
  final String? currentStage;
  final String? appliedAt;
  final ApplicationJob? job;

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      ApplicationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String?,
        statusLabel: json['status_label'] as String?,
        aiMatchScore: json['ai_match_score'] as num?,
        currentStage: json['current_stage'] as String?,
        appliedAt: json['applied_at'] as String?,
        job: json['job'] is Map
            ? ApplicationJob.fromJson(
                (json['job'] as Map).cast<String, dynamic>(),
              )
            : null,
      );
}

class ApplicationJob {
  const ApplicationJob({
    required this.id,
    required this.title,
    required this.slug,
    required this.companyName,
    this.companySlug,
    this.companyLogoUrl,
  });

  final int id;
  final String title;
  final String slug;
  final String companyName;
  final String? companySlug;
  final String? companyLogoUrl;

  factory ApplicationJob.fromJson(Map<String, dynamic> json) {
    final company = (json['company'] as Map?)?.cast<String, dynamic>() ?? {};

    return ApplicationJob(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      companyName: company['name'] as String? ?? '-',
      companySlug: company['slug'] as String?,
      companyLogoUrl: company['logo_url'] as String?,
    );
  }
}
