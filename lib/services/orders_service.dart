import 'api_client.dart';
import '../models/order.dart';
import '../models/professional.dart';

class OrdersService {
  OrdersService._internal();
  static final OrdersService instance = OrdersService._internal();

  final _api = ApiClient.instance;

  // ---- Customer side ----

  /// Confirmed against the real backend (GET /api/professionals):
  /// it already decides online-only vs offline-fallback itself and
  /// reports which one happened via `usedOfflineFallback` - this
  /// just passes that straight through rather than re-filtering
  /// client-side.
  Future<(List<Professional>, bool)> searchBaas({
    double? lat,
    double? lng,
    double radius = 30,
    String? service,
  }) async {
    final data = await _api.get('/api/professionals', query: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'radius': radius,
      if (service != null) 'service': service,
    });
    final list = (data['professionals'] as List?) ?? [];
    final professionals = list.map((e) => Professional.fromJson(e as Map<String, dynamic>)).toList();
    final usedOfflineFallback = data['usedOfflineFallback'] == true;
    return (professionals, usedOfflineFallback);
  }

  Future<MybaasOrder> createOrder({
    required String service,
    String? professionalId,
    String? professionalName,
    required String location,
    required int days,
    required double dailyRate,
    required String preferredDate,
    required String paymentMethod, // "pay_now" | "pay_direct"
    double? latitude,
    double? longitude,
  }) async {
    final data = await _api.post('/api/orders', body: {
      'service': service,
      if (professionalId != null) 'professionalId': professionalId,
      if (professionalName != null) 'professionalName': professionalName,
      'location': location,
      'days': days,
      'dailyRate': dailyRate,
      'preferredDate': preferredDate,
      'paymentMethod': paymentMethod,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'photos': [],
    });
    // Throws ApiException(code: 'MOBILE_REQUIRED') automatically via
    // ApiClient if the account has no verified mobile yet - catch
    // that in the UI, run the OTP flow, then call this again.
    return MybaasOrder.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<List<MybaasOrder>> myOrders() async {
    final data = await _api.get('/api/orders');
    final list = (data['orders'] as List?) ?? [];
    return list.map((e) => MybaasOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns the PayHere payment-object fields - feed straight into
  /// the PayHere mobile SDK's start-payment call.
  /// Confirmed against the real backend: POST /api/orders/:id/payment/payhere
  /// returns {success, payment: {...}, order: {...}} - `payment`
  /// is already in the exact snake_case shape PayHere's JS SDK
  /// expects (merchant_id, order_id, items, notify_url all
  /// included), unlike the wallet top-up endpoint's flat camelCase
  /// response - no field mapping needed here, just unwrap `payment`.
  Future<Map<String, dynamic>> getPayHerePayment(String orderId) async {
    final data = await _api.post('/api/orders/$orderId/payment/payhere');
    return {
      ...(data['payment'] as Map<String, dynamic>? ?? {}),
      'return_url': null,
      'cancel_url': null,
    };
  }

  /// Confirmed against the real backend: POST /api/orders/:id/payment/wallet
  /// takes no body - it charges the order's own total from the
  /// customer's wallet balance directly. Only valid for a
  /// paymentMethod: 'pay_now' order that hasn't been paid yet.
  Future<void> payOrderWithWallet(String orderId) async {
    await _api.post('/api/orders/$orderId/payment/wallet');
  }

  Future<void> notifyPaymentFailed(String orderId) async {
    await _api.post('/api/orders/$orderId/payment-failed');
  }

  /// Confirmed against the real backend: PUT /api/orders/:id/status
  /// {status: 'Cancelled'} - a customer can cancel their own order
  /// (this is the one status change non-admins are allowed to make).
  /// Used when a pay_now payment fails or is abandoned, so the order
  /// doesn't linger unpaid in My Orders - the customer just starts
  /// over with a fresh hire attempt instead.
  Future<void> cancelOrder(String orderId) async {
    await _api.put('/api/orders/$orderId/status', body: {'status': 'Cancelled'});
  }

  // ---- Baas side ----

  Future<List<MybaasOrder>> baasOrders(String type) async {
    // type: "incoming" | "active" | "completed"
    final data = await _api.get('/api/baas/orders', query: {'type': type});
    final list = (data['orders'] as List?) ?? [];
    return list.map((e) => MybaasOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> acceptOrder(String orderId) => _api.post('/api/orders/$orderId/accept');
  Future<void> rejectOrder(String orderId) => _api.post('/api/orders/$orderId/reject');
  Future<void> completeOrder(String orderId) => _api.put('/api/orders/$orderId/complete');
}
