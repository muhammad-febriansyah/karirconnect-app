/// One row of `GET api/v1/notifications`.
///
/// Laravel database notifications, so `id` is a UUID string rather than an int.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    this.type,
    this.actionUrl,
    this.readAt,
    this.createdAt,
  });

  final String id;

  /// `class_basename` of the notification class, e.g. `ApplicationStatusChanged`.
  final String? type;

  final String title;
  final String body;

  /// A **web** path such as `/employee/applications/3`. There is no mobile
  /// route table for these, so it is kept for a future deep-link mapping rather
  /// than navigated to blindly.
  final String? actionUrl;

  final String icon;
  final String? readAt;
  final String? createdAt;

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id']?.toString() ?? '',
        type: json['type'] as String?,
        title: json['title'] as String? ?? 'Notifikasi',
        body: json['body'] as String? ?? '',
        actionUrl: json['action_url'] as String?,
        icon: json['icon'] as String? ?? 'bell',
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
