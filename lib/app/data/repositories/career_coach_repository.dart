import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/coach_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/career-coach` — behind `auth:api` + `role:employee`, so every call
/// 401s without a session.
class CareerCoachRepository with ApiRequestMixin {
  CareerCoachRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// Session list. Index rows carry no messages; `meta.total` only.
  Future<List<CoachSession>> sessions({int perPage = 20}) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/career-coach',
        query: <String, dynamic>{'per_page': perPage},
      ),
    );

    return (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => CoachSession.fromJson(row.cast<String, dynamic>()))
        .toList();
  }

  /// Full session with its thread.
  Future<CoachSession> session(int id) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/career-coach/$id'));

    return CoachSession.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Opens a new session with a first message. The server stores the coach's
  /// reply before responding, but returns only `{id, title}` — fetch [session]
  /// afterwards to get the populated thread.
  Future<int> start(String message) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/career-coach',
        data: {'message': message},
      ),
    );

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (data['id'] as num?)?.toInt() ?? 0;
  }

  /// Sends a message to an existing session and returns the coach's reply.
  Future<CoachMessage> reply(int sessionId, String message) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/career-coach/$sessionId/send',
        data: {'message': message},
      ),
    );

    return CoachMessage.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<void> archive(int sessionId) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/career-coach/$sessionId/archive',
          ));
}
