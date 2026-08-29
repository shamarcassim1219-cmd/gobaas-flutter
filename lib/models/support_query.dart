class ChatMessage {
  final String id;
  final String senderType; // 'customer' | 'admin' - confirmed field name
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  bool get isFromCustomer => senderType == 'customer';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderType: json['senderType'] as String? ?? 'admin',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// A single support conversation thread ("query"). Confirmed
/// against the real backend: status flips to 'closed' server-side
/// (see the backend's own inactivity handling) - this client only
/// ever reads whatever `status` it reports, since a purely
/// client-side timer can't fire once the app is backgrounded.
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
