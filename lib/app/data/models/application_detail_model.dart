import 'application_model.dart';

/// `GET api/v1/applications/{id}` — `ApplicationDetailResource` extends
/// `ApplicationResource`, so [application] holds the shared fields.
class ApplicationDetailModel {
  const ApplicationDetailModel({
    required this.application,
    required this.statusLogs,
    this.coverLetter,
    this.expectedSalary,
    this.screeningScore,
    this.reviewedAt,
    this.cvLabel,
    this.cvUrl,
  });

  final ApplicationModel application;

  final String? coverLetter;
  final int? expectedSalary;
  final num? screeningScore;
  final String? reviewedAt;

  final String? cvLabel;
  final String? cvUrl;

  /// The status history, oldest first as the API returns it.
  final List<ApplicationStatusLog> statusLogs;

  factory ApplicationDetailModel.fromJson(Map<String, dynamic> json) {
    final cv = (json['cv'] as Map?)?.cast<String, dynamic>();

    return ApplicationDetailModel(
      application: ApplicationModel.fromJson(json),
      coverLetter: json['cover_letter'] as String?,
      expectedSalary: (json['expected_salary'] as num?)?.toInt(),
      screeningScore: json['screening_score'] as num?,
      reviewedAt: json['reviewed_at'] as String?,
      cvLabel: cv?['label'] as String?,
      cvUrl: cv?['url'] as String?,
      statusLogs: (json['status_logs'] as List? ?? const [])
          .whereType<Map>()
          .map((row) =>
              ApplicationStatusLog.fromJson(row.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ApplicationStatusLog {
  const ApplicationStatusLog({
    required this.id,
    this.fromStatus,
    this.toStatus,
    this.note,
    this.changedBy,
    this.createdAt,
  });

  final int id;
  final String? fromStatus;
  final String? toStatus;
  final String? note;
  final String? changedBy;
  final String? createdAt;

  factory ApplicationStatusLog.fromJson(Map<String, dynamic> json) =>
      ApplicationStatusLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fromStatus: json['from_status'] as String?,
        toStatus: json['to_status'] as String?,
        note: json['note'] as String?,
        changedBy: json['changed_by'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
