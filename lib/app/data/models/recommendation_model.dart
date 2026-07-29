import 'job_model.dart';

/// One row of `GET api/v1/recommendations`.
///
/// The job itself goes through `JobResource`, so the salary and anonymity
/// masking still applies — the recommender's raw model is never exposed.
class RecommendationModel {
  const RecommendationModel({
    required this.job,
    required this.score,
    required this.explanation,
  });

  final JobModel job;

  /// 0–100 match score.
  final num score;

  /// Human-readable reasons the job matched, straight from the recommender.
  final List<String> explanation;

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      RecommendationModel(
        job: JobModel.fromJson(
          (json['job'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        score: (json['score'] as num?) ?? 0,
        explanation: _explanation(json['explanation']),
      );

  /// The API sends this as one pre-joined string — `"2 dari 5 skill cocok ·
  /// gaji memenuhi ekspektasi"` — not as an array. Splitting on the separator
  /// gets the individual reasons back so each renders as its own bullet. A list
  /// is still accepted in case the payload ever changes.
  static List<String> _explanation(dynamic raw) {
    if (raw is List) {
      return raw.map((reason) => reason.toString()).toList();
    }

    if (raw is String) {
      return raw
          .split('·')
          .map((reason) => reason.trim())
          .where((reason) => reason.isNotEmpty)
          .toList();
    }

    return const [];
  }
}
