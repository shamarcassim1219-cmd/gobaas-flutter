class ChatMessage {
  final String id;
  final String sender; // 'customer' | 'admin'
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  bool get isFromCustomer => sender == 'customer';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sender: json['sender'] as String? ?? 'admin',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// A single support conversation thread ("query"). Mirrors the
/// admin-side "live chats" concept referenced elsewhere in this
/// project - status flips to 'closed' after the backend's own
/// inactivity timeout (assumed 30 minutes, enforced server-side -
/// a client can't reliably auto-close something on its own timer
/// once the app is backgrounded or killed).
class SupportQuery {
  final String id;
  final String status; // 'open' | 'closed'
  final List<ChatMessage> messages;

  SupportQuery({
    required this.id,
    required this.status,
    required this.messages,
  });

  bool get isOpen => status == 'open';

  factory SupportQuery.fromJson(Map<String, dynamic> json) {
    final messagesRaw = (json['messages'] as List?) ?? [];
    return SupportQuery(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      messages: messagesRaw.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
