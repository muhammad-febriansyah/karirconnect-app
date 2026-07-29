// `api/v1/career-coach` — the AI career-coach chat. Sessions and their messages
// are hand-built in the controller rather than resource classes, so the shapes
// here mirror those arrays exactly.

/// One chat session. The index carries no messages; only `GET
/// career-coach/{id}` populates [messages].
class CoachSession {
  const CoachSession({
    required this.id,
    required this.title,
    required this.status,
    required this.messages,
    this.lastMessageAt,
  });

  final int id;
  final String title;

  /// `active` or `archived`.
  final String status;

  final String? lastMessageAt;

  final List<CoachMessage> messages;

  CoachSession copyWith({List<CoachMessage>? messages}) => CoachSession(
        id: id,
        title: title,
        status: status,
        lastMessageAt: lastMessageAt,
        messages: messages ?? this.messages,
      );

  factory CoachSession.fromJson(Map<String, dynamic> json) => CoachSession(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? 'Sesi tanpa judul',
        status: json['status'] as String? ?? 'active',
        lastMessageAt: json['last_message_at'] as String?,
        messages: (json['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => CoachMessage.fromJson(row.cast<String, dynamic>()))
            .toList(),
      );
}

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });

  final int id;

  /// `user` or `assistant`. `system` is never sent to the client.
  final String role;

  final String content;
  final String? createdAt;

  bool get isMine => role == 'user';

  factory CoachMessage.fromJson(Map<String, dynamic> json) => CoachMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        role: json['role'] as String? ?? 'assistant',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}
