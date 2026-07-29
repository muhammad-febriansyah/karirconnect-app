/// Mirrors `App\Http\Resources\Api\V1\InterviewResource`.
///
/// `job` and `participants` are `whenLoaded`, so both are absent on endpoints
/// that do not eager load them.
class InterviewModel {
  const InterviewModel({
    required this.id,
    required this.title,
    required this.requiresConfirmation,
    required this.participants,
    this.stage,
    this.mode,
    this.status,
    this.scheduledAt,
    this.durationMinutes,
    this.timezone,
    this.confirmedAt,
    this.meetingUrl,
    this.meetingPasscode,
    this.locationName,
    this.locationAddress,
    this.locationMapUrl,
    this.candidateInstructions,
    this.job,
  });

  final int id;
  final String title;
  final String? stage;

  /// `onsite`, `online`, `phone`, … — decides whether the meeting URL or the
  /// address block is the useful one.
  final String? mode;

  final String? status;
  final String? scheduledAt;
  final int? durationMinutes;
  final String? timezone;
  final String? confirmedAt;
  final bool requiresConfirmation;

  final String? meetingUrl;
  final String? meetingPasscode;
  final String? locationName;
  final String? locationAddress;
  final String? locationMapUrl;
  final String? candidateInstructions;

  final InterviewJob? job;
  final List<InterviewParticipant> participants;

  bool get isConfirmed => confirmedAt != null;

  /// True while the candidate still owes an answer to the invitation.
  bool get needsResponse => requiresConfirmation && confirmedAt == null;

  factory InterviewModel.fromJson(Map<String, dynamic> json) => InterviewModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? 'Interview',
        stage: json['stage'] as String?,
        mode: json['mode'] as String?,
        status: json['status'] as String?,
        scheduledAt: json['scheduled_at'] as String?,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
        timezone: json['timezone'] as String?,
        confirmedAt: json['confirmed_at'] as String?,
        requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
        meetingUrl: json['meeting_url'] as String?,
        meetingPasscode: json['meeting_passcode'] as String?,
        locationName: json['location_name'] as String?,
        locationAddress: json['location_address'] as String?,
        locationMapUrl: json['location_map_url'] as String?,
        candidateInstructions: json['candidate_instructions'] as String?,
        job: json['job'] is Map
            ? InterviewJob.fromJson((json['job'] as Map).cast<String, dynamic>())
            : null,
        participants: (json['participants'] as List? ?? const [])
            .whereType<Map>()
            .map((row) =>
                InterviewParticipant.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
}

class InterviewJob {
  const InterviewJob({this.id, this.title, this.slug, this.company});

  final int? id;
  final String? title;
  final String? slug;
  final String? company;

  factory InterviewJob.fromJson(Map<String, dynamic> json) => InterviewJob(
        id: (json['id'] as num?)?.toInt(),
        title: json['title'] as String?,
        slug: json['slug'] as String?,
        company: json['company'] as String?,
      );
}

class InterviewParticipant {
  const InterviewParticipant({
    required this.id,
    this.name,
    this.role,
    this.invitationResponse,
    this.respondedAt,
  });

  final int id;
  final String? name;
  final String? role;

  /// `accepted`, `declined` or `tentative`.
  final String? invitationResponse;

  final String? respondedAt;

  factory InterviewParticipant.fromJson(Map<String, dynamic> json) =>
      InterviewParticipant(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String?,
        role: json['role'] as String?,
        invitationResponse: json['invitation_response'] as String?,
        respondedAt: json['responded_at'] as String?,
      );
}
