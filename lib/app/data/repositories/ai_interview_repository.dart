import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/ai_interview_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/ai-interviews` — text-mode practice, behind `auth:api` +
/// `role:employee`.
class AiInterviewRepository with ApiRequestMixin {
  AiInterviewRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  Future<List<InterviewSession>> sessions({int perPage = 20}) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/ai-interviews',
        query: <String, dynamic>{'per_page': perPage},
      ),
    );

    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => InterviewSession.fromJson(row.cast<String, dynamic>()))
        .toList();
  }

  /// Start a practice session. 422s with a `quota` key when the monthly free
  /// limit is spent — [ApiException.message] carries that.
  Future<InterviewDetail> startPractice({String language = 'id'}) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/ai-interviews/practice',
        data: {'language': language},
      ),
    );

    return InterviewDetail.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<InterviewDetail> detail(int id) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/ai-interviews/$id'));

    return InterviewDetail.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<void> answer(
    int sessionId,
    int questionId,
    String answer, {
    int? durationSeconds,
  }) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/ai-interviews/$sessionId/questions/$questionId/answer',
            data: {
              'answer': answer,
              'duration_seconds': ?durationSeconds,
            },
          ));

  /// Finalise — kicks off the AI analysis. The result may still be `analyzing`
  /// immediately after, so [result] is polled separately.
  Future<void> complete(int sessionId) => send(
        () => _api.post<Map<String, dynamic>>('/ai-interviews/$sessionId/complete'),
      );

  Future<InterviewResult> result(int id) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>('/ai-interviews/$id/result'),
    );

    return InterviewResult.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
