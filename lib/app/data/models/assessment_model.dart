// `api/v1/skill-assessments`. The controller hand-builds every shape, so these
// mirror the arrays directly rather than going through resource classes.

/// A skill the candidate can be tested on, from the `skills` array of the
/// index.
class AssessmentSkill {
  const AssessmentSkill({
    required this.id,
    required this.name,
    required this.questionCount,
    this.category,
  });

  final int id;
  final String name;
  final String? category;
  final int questionCount;

  factory AssessmentSkill.fromJson(Map<String, dynamic> json) =>
      AssessmentSkill(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '-',
        category: json['category'] as String?,
        questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      );
}

/// The `present()` shape — an attempt without its questions. Shared by the
/// index list, `store`, and `submit`.
class AssessmentAttempt {
  const AssessmentAttempt({
    required this.id,
    required this.status,
    required this.totalQuestions,
    this.skill,
    this.skillId,
    this.score,
    this.correctAnswers,
    this.startedAt,
    this.completedAt,
    this.expiresAt,
  });

  final int id;
  final String? skill;
  final int? skillId;

  /// `in_progress` or `completed`.
  final String status;

  /// 0–100, null until submitted.
  final num? score;

  final int totalQuestions;
  final int? correctAnswers;
  final String? startedAt;
  final String? completedAt;
  final String? expiresAt;

  bool get isCompleted => status == 'completed';

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) =>
      AssessmentAttempt(
        id: (json['id'] as num?)?.toInt() ?? 0,
        skill: json['skill'] as String?,
        skillId: (json['skill_id'] as num?)?.toInt(),
        status: json['status'] as String? ?? 'in_progress',
        score: json['score'] as num?,
        totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
        correctAnswers: (json['correct_answers'] as num?)?.toInt(),
        startedAt: json['started_at'] as String?,
        completedAt: json['completed_at'] as String?,
        expiresAt: json['expires_at'] as String?,
      );
}

/// An attempt plus its questions, from `GET skill-assessments/{id}`.
class AssessmentDetail {
  const AssessmentDetail({required this.attempt, required this.questions});

  final AssessmentAttempt attempt;
  final List<AssessmentQuestion> questions;

  factory AssessmentDetail.fromJson(Map<String, dynamic> json) =>
      AssessmentDetail(
        attempt: AssessmentAttempt.fromJson(json),
        questions: (json['questions'] as List? ?? const [])
            .whereType<Map>()
            .map((row) =>
                AssessmentQuestion.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
}

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.type,
    this.difficulty,
    this.answer,
    this.isCorrect,
    this.correctAnswer,
  });

  final int id;

  /// `multiple_choice`, `boolean`, `text`, or `code`.
  final String? type;

  final String question;

  /// Empty for the free-text types.
  final List<String> options;

  final String? difficulty;

  /// The saved answer value (empty until answered).
  final String? answer;

  /// Null until the assessment is submitted — the server withholds the key.
  final bool? isCorrect;
  final String? correctAnswer;

  /// Options carry the choice; anything else is a free-text answer.
  bool get isChoice => options.isNotEmpty;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) =>
      AssessmentQuestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: json['type'] as String?,
        question: json['question'] as String? ?? '',
        options: (json['options'] as List? ?? const [])
            .map((option) => option.toString())
            .toList(),
        difficulty: json['difficulty'] as String?,
        answer: json['answer'] as String?,
        isCorrect: json['is_correct'] as bool?,
        correctAnswer: json['correct_answer'] as String?,
      );
}
