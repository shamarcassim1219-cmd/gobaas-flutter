import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

/// Registers this device for real push notifications (Firebase
/// Cloud Messaging) - reaches the device even when the app is
/// closed or backgrounded, unlike NotificationService's 45-second
/// polling, which only runs while the app is open. Kept as a
/// separate service since it's purely about device registration and
/// message plumbing, not the notification data itself.
class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance = PushNotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  bool _permissionRequested = false;

  /// Call after every session change (fresh guest session, login,
  /// or register) - not just once at app startup. The permission
  /// request and refresh-listener only need to happen once per app
  /// process, but the token itself must be re-sent to the backend
  /// every time, since a different account logging in on the same
  /// device needs this same device's token re-associated with the
  /// new user's id (the backend endpoint attaches it to whichever
  /// account's auth token this call is made with).
  Future<void> initialize() async {
    try {
      if (!_permissionRequested) {
        _permissionRequested = true;
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
        // Firebase occasionally rotates the token - keep the backend
        // in sync whenever that happens, not just at first launch.
        _messaging.onTokenRefresh.listen(_registerToken);
      }

      final token = await _messaging.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {
      // Push registration failing (e.g. no Google Play Services on
      // this device) should never block the rest of the app.
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiClient.instance.post('/api/users/fcm-token', body: {'fcmToken': token});
    } catch (_) {
      // Silent - the next app open (or token refresh) tries again.
    }
  }
}

/// Required top-level (not a class method) entry point for handling
/// a push that arrives while the app is fully closed or backgrounded -
/// the plugin calls this in a separate isolate, so it can't be a
/// closure over any app state. It intentionally does nothing beyond
/// letting the OS show the notification itself (the default
/// behavior for a message with a `notification` payload); this app
/// doesn't need custom background data processing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
