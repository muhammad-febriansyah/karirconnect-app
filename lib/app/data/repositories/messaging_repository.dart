import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/conversation_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/conversations`.
///
/// Messaging sits outside the role-scoped groups server-side — recruiters and
/// candidates share these endpoints — so it is not part of
/// `EmployeeRepository`. It still needs a session.
class MessagingRepository with ApiRequestMixin {
  MessagingRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// The index is hand-built rather than a resource collection, so `meta`
  /// carries only `total` and `unread_count`, and rows have no `messages`.
  Future<({List<ConversationModel> items, int unreadCount})> conversations({
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/conversations',
        query: <String, dynamic>{'per_page': perPage},
      ),
    );

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      items: (response['data'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => ConversationModel.fromJson(row.cast<String, dynamic>()))
          .toList(),
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Opening a thread marks it read server-side, matching the web.
  Future<ConversationModel> conversation(int id) async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/conversations/$id'));

    return ConversationModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Body is capped at 5000 characters server-side.
  Future<MessageModel> sendMessage(int conversationId, String body) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/conversations/$conversationId/messages',
        data: {'body': body},
      ),
    );

    return MessageModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<void> markRead(int conversationId) =>
      send(() => _api.post<Map<String, dynamic>>(
            '/conversations/$conversationId/read',
          ));
}
