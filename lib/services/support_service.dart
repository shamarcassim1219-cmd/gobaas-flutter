import 'api_client.dart';
import '../models/support_query.dart';

/// NOTE: endpoint paths/payloads here try "complaints" terminology
/// (the original project notes referenced "complaint threads" on
/// the admin side) after the first guess using "support/query" 404d
/// - still not independently re-verified against the backend in
/// this session. If this also 404s, that's strong evidence this
/// customer-facing chat submission isn't built on the backend yet
/// rather than just a wrong path guess.
///
/// The 30-minute auto-close-on-inactivity behavior is assumed to be
/// enforced server-side (a scheduled job) - this client only ever
/// reads whatever `status` the backend reports, since a purely
/// client-side timer can't fire once the app is backgrounded.
class SupportService {
  SupportService._internal();
  static final SupportService instance = SupportService._internal();

  final _api = ApiClient.instance;

  /// Starts a new support conversation. Call this once per
  /// conversation - reuse the returned id for sendMessage/getQuery
  /// rather than creating a new one per message.
  Future<SupportQuery> createQuery() async {
    final data = await _api.post('/api/complaints', body: {});
    return SupportQuery.fromJson(data['complaint'] as Map<String, dynamic>? ?? data);
  }

  /// Polls the current state of a conversation - its status and
  /// full message history, so a simple timer-based poll (matching
  /// NotificationService's pattern) is enough for near-live updates
  /// without needing a persistent SSE/WebSocket connection.
  Future<SupportQuery> getQuery(String queryId) async {
    final data = await _api.get('/api/complaints/$queryId');
    return SupportQuery.fromJson(data['complaint'] as Map<String, dynamic>? ?? data);
  }

  Future<void> sendMessage(String queryId, String message) async {
    await _api.post('/api/complaints/$queryId/messages', body: {
      'message': message,
    });
  }
}
