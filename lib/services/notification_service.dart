import 'dart:async';
import 'api_client.dart';
import '../models/notification.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _api = ApiClient.instance;
  Timer? _pollTimer;

  Future<List<MybaasNotification>> list() async {
    final data = await _api.get('/api/notifications');
    final items = (data['notifications'] as List?) ?? [];
    return items.map((e) => MybaasNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final items = await list();
    return items.where((n) => !n.read).length;
  }

  Future<void> markRead(String id) => _api.put('/api/notifications/$id/read');
  Future<void> markAllRead() => _api.put('/api/notifications/read-all');
  Future<void> delete(String id) => _api.delete('/api/notifications/$id');

  /// Simplest real-time approach to start with — poll every 45s while
  /// the app is in the foreground. The web apps fall back to this
  /// exact interval whenever their SSE connection drops, so it is a
  /// known-safe baseline; swap in flutter_client_sse against
  /// GET /api/notifications/stream?token=... later for instant push
  /// without changing anything that calls this service.
  void startPolling(void Function(List<MybaasNotification>) onUpdate) {
    stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      try {
        onUpdate(await list());
      } catch (_) {
        // Silent - next tick tries again. Matches the web apps'
        // "never let a background refresh surface an error" approach.
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
