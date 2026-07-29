import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/assessment_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/skill-assessments` — behind `auth:api` + `role:employee`.
class SkillAssessmentRepository with ApiRequestMixin {
  SkillAssessmentRepository({ApiService? api})
      : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// Assessable skills plus this candidate's past attempts.
  Future<({List<AssessmentSkill> skills, List<AssessmentAttempt> attempts})>
      overview() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/skill-assessments'));

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      skills: (data['skills'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => AssessmentSkill.fromJson(row.cast<String, dynamic>()))
          .toList(),
      attempts: (data['assessments'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => AssessmentAttempt.fromJson(row.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Start (or resume) an assessment for a skill.
  Future<AssessmentAttempt> start(int skillId) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/skill-assessments',
        data: {'skill_id': skillId},
      ),
    );

    return AssessmentAttempt.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<AssessmentDetail> detail(int id) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>('/skill-assessments/$id'),
    );

    return AssessmentDetail.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Submits every answer at once. [answers] is keyed by question id; the
  /// server expects `{ "<id>": {"value": "..."} }`.
  Future<AssessmentAttempt> submit(int id, Map<int, String> answers) async {
    final payload = <String, dynamic>{
      for (final entry in answers.entries)
        '${entry.key}': {'value': entry.value},
    };

    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/skill-assessments/$id/submit',
        data: {'answers': payload},
      ),
    );

    return AssessmentAttempt.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
