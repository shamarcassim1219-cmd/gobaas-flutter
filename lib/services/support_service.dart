import 'api_client.dart';
import '../models/support_query.dart';

/// Confirmed against the real backend:
/// - GET /api/support/chats -> {success, chats} - this user's own
///   chats, newest first
/// - POST /api/support/chats -> {success, chat} - creates one, or
///   returns the existing open one for this user if there already
///   is one (idempotent, safe to call more than once).
/// - GET /api/support/chats/:id -> {success, chat, messages} - note
///   messages is a top-level sibling of chat, not nested inside it.
/// - POST /api/support/chats/:id/messages -> {message: text}
class SupportService {
  SupportService._internal();
  static final SupportService instance = SupportService._internal();

  final _api = ApiClient.instance;

  /// The most recent OPEN chat, if any - lets the chat screen
  /// resume an existing conversation on open rather than always
  /// starting blank.
  Future<SupportQuery?> mostRecentOpenChat() async {
    final data = await _api.get('/api/support/chats');
    final chats = (data['chats'] as List?) ?? [];
    if (chats.isEmpty) return null;

    final openChat = chats.cast<Map<String, dynamic>>().firstWhere(
          (c) => (c['status'] as String? ?? 'open') == 'open',
          orElse: () => const {},
        );
    if (openChat.isEmpty) return null;

    return getQuery(openChat['id'] as String? ?? '');
  }

  Future<SupportQuery> createQuery() async {
    final data = await _api.post('/api/support/chats', body: {});
    return SupportQuery.fromJson({
      ...(data['chat'] as Map<String, dynamic>? ?? {}),
      'messages': const [],
    });
  }

  Future<SupportQuery> getQuery(String queryId) async {
    final data = await _api.get('/api/support/chats/$queryId');
    return SupportQuery.fromJson({
      ...(data['chat'] as Map<String, dynamic>? ?? {}),
      'messages': data['messages'] ?? const [],
    });
  }

  Future<void> sendMessage(String queryId, String message) async {
    await _api.post('/api/support/chats/$queryId/messages', body: {
      'message': message,
    });
  }
}
