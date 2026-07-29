import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/notification_model.dart';
import '../models/paginated.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/notifications` — the in-app inbox.
///
/// Push is deliberately out of scope: `POST/DELETE api/v1/device-tokens` exists
/// server-side but is not called here, so nothing in this client depends on
/// Firebase. Wiring FCM later means registering the token against those two
/// routes and leaving everything below unchanged.
class NotificationRepository with ApiRequestMixin {
  NotificationRepository({ApiService? api})
      : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// Returns the page plus the unread total the response reports, which is what
  /// the bell badge shows.
  Future<({Paginated<NotificationModel> page, int unreadCount})> notifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>(
        '/notifications',
        query: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (unreadOnly) 'unread_only': 1,
        },
      ),
    );

    final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (
      page: Paginated.fromJson(response, NotificationModel.fromJson),
      unreadCount: (meta['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Badge count plus the five most recent unread, for the bell icon.
  Future<int> unreadCount() async {
    final response = await send(
      () => _api.get<Map<String, dynamic>>('/notifications/unread'),
    );

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// Ids are Laravel database-notification UUIDs, not ints.
  Future<void> markRead(String id) =>
      send(() => _api.post<Map<String, dynamic>>('/notifications/$id/read'));

  Future<void> markAllRead() =>
      send(() => _api.post<Map<String, dynamic>>('/notifications/read-all'));

  Future<void> destroy(String id) =>
      send(() => _api.delete<Map<String, dynamic>>('/notifications/$id'));
}
