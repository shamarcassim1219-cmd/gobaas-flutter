import 'api_client.dart';
import '../models/support_query.dart';

/// NOTE: endpoint paths/payloads here are inferred from the general
/// "live chats" / "complaint threads" concept referenced elsewhere
/// in this project (admin panel manages live chats) - not
/// independently re-verified against the backend in this session.
/// If any of these 404 or return an unexpected shape, that confirms
/// the real contract and this should be corrected to match it.
///
/// The 30-minute auto-close-on-inactivity behavior is assumed to be
/// enforced server-side (a scheduled job) - this client only ever
/// reads whatever `status` the backend reports, since a purely
/// client-side timer can't fire once the app is backgrounded.
class SupportService {
  SupportService._internal();
  static final SupportService instance = SupportService._internal();

  final _api = ApiClient.instance;

  /// Starts a new support query (chat thread). Call this once per
  /// conversation - reuse the returned id for sendMessage/getQuery
  /// rather than creating a new query per message.
  Future<SupportQuery> createQuery() async {
    final data = await _api.post('/api/support/query', body: {});
    return SupportQuery.fromJson(data['query'] as Map<String, dynamic>? ?? data);
  }

  /// Polls the current state of a query - its status and full
  /// message history, so a simple timer-based poll (matching
  /// NotificationService's pattern) is enough for near-live updates
  /// without needing a persistent SSE/WebSocket connection.
  Future<SupportQuery> getQuery(String queryId) async {
    final data = await _api.get('/api/support/query/$queryId');
    return SupportQuery.fromJson(data['query'] as Map<String, dynamic>? ?? data);
  }

  Future<void> sendMessage(String queryId, String message) async {
    await _api.post('/api/support/query/$queryId/message', body: {
      'message': message,
    });
  }
}
