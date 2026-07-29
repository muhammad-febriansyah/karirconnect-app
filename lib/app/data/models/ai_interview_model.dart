// `api/v1/ai-interviews` — text-mode practice interviews. Every shape is
// hand-built in the controller, so these mirror the arrays directly.

/// The `present()` shape — a session without its questions or analysis.
class InterviewSession {
  const InterviewSession({
    required this.id,
    required this.status,
    this.language,
    this.isPractice = true,
    this.jobTitle,
    this.createdAt,
    this.expiresAt,
  });

  final int id;

  /// `pending`, `in_progress`, `analyzing`, `completed`, `expired`,
  /// `cancelled`.
  final String status;

  final String? language;
  final bool isPractice;
  final String? jobTitle;
  final String? createdAt;
  final String? expiresAt;

  bool get isCompleted => status == 'completed';
  bool get isAnalyzing => status == 'analyzing';

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    final job = (json['job'] as Map?)?.cast<String, dynamic>();

    return InterviewSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      language: json['language'] as String?,
      isPractice: json['is_practice'] as bool? ?? true,
      jobTitle: job?['title'] as String?,
      createdAt: json['created_at'] as String?,
      expiresAt: json['expires_at'] as String?,
    );
  }
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.orderNumber,
    required this.question,
    this.answered = false,
    this.answer,
  });

  final int id;
  final int orderNumber;
  final String question;
  final bool answered;
  final String? answer;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderNumber: (json['order_number'] as num?)?.toInt() ?? 0,
        question: json['question'] as String? ?? '',
        answered: json['answered'] as bool? ?? false,
        answer: json['answer'] as String?,
      );
}

/// Session + questions, from `startPractice` and `GET ai-interviews/{id}`.
class InterviewDetail {
  const InterviewDetail({required this.session, required this.questions});

  final InterviewSession session;
  final List<InterviewQuestion> questions;

  factory InterviewDetail.fromJson(Map<String, dynamic> json) =>
      InterviewDetail(
        session: InterviewSession.fromJson(json),
        questions: (json['questions'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => InterviewQuestion.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
}

/// The AI verdict, from `GET ai-interviews/{id}/result`. Null while the session
/// is still `analyzing`.
class InterviewAnalysis {
  const InterviewAnalysis({
    this.status,
    this.overallScore,
    this.summary,
    this.strengths = const [],
    this.weaknesses = const [],
    this.recommendation,
  });

  final String? status;
  final int? overallScore;
  final String? summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String? recommendation;

  factory InterviewAnalysis.fromJson(Map<String, dynamic> json) =>
      InterviewAnalysis(
        status: json['status'] as String?,
        overallScore: (json['overall_score'] as num?)?.toInt(),
        summary: json['summary'] as String?,
        strengths: (json['strengths'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        weaknesses: (json['weaknesses'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        recommendation: json['recommendation'] as String?,
      );
}

class InterviewResult {
  const InterviewResult({required this.session, this.analysis});

  final InterviewSession session;
  final InterviewAnalysis? analysis;

  factory InterviewResult.fromJson(Map<String, dynamic> json) {
    final analysis = (json['analysis'] as Map?)?.cast<String, dynamic>();

    return InterviewResult(
      session: InterviewSession.fromJson(json),
      analysis: analysis == null ? null : InterviewAnalysis.fromJson(analysis),
    );
  }
}
