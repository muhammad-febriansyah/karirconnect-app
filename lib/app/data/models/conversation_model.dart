/// A thread from `GET api/v1/conversations`.
///
/// Messaging is not role-scoped server-side — both recruiters and candidates
/// use the same endpoints — so this lives outside the employee repository.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.participants,
    required this.messages,
    this.type,
    this.subject,
    this.lastMessageAt,
    this.updatedAt,
  });

  final int id;
  final String? type;
  final String? subject;
  final List<ConversationParticipant> participants;
  final String? lastMessageAt;
  final String? updatedAt;

  /// Only populated by `GET conversations/{id}`; the index omits it.
  final List<MessageModel> messages;

  /// The other side of the thread, which is what the list row should show.
  ConversationParticipant? get counterpart =>
      participants.where((participant) => !participant.isMe).firstOrNull;

  String get title =>
      subject?.isNotEmpty == true ? subject! : (counterpart?.name ?? 'Percakapan');

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: json['type'] as String?,
        subject: json['subject'] as String?,
        participants: (json['participants'] as List? ?? const [])
            .whereType<Map>()
            .map((row) =>
                ConversationParticipant.fromJson(row.cast<String, dynamic>()))
            .toList(),
        messages: (json['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((row) => MessageModel.fromJson(row.cast<String, dynamic>()))
            .toList(),
        lastMessageAt: json['last_message_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class ConversationParticipant {
  const ConversationParticipant({
    required this.isMe,
    this.id,
    this.name,
    this.avatarUrl,
  });

  final int? id;
  final String? name;
  final String? avatarUrl;
  final bool isMe;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) =>
      ConversationParticipant(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isMe: json['is_me'] as bool? ?? false,
      );
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.body,
    required this.isMine,
    this.senderName,
    this.senderAvatarUrl,
    this.createdAt,
  });

  final int id;
  final String body;
  final bool isMine;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? createdAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = (json['sender'] as Map?)?.cast<String, dynamic>() ?? const {};

    return MessageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: json['body'] as String? ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      senderName: sender['name'] as String?,
      senderAvatarUrl: sender['avatar_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
