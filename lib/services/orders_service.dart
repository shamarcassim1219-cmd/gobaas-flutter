import 'api_client.dart';
import '../models/order.dart';
import '../models/professional.dart';

class OrdersService {
  OrdersService._internal();
  static final OrdersService instance = OrdersService._internal();

  final _api = ApiClient.instance;

  // ---- Customer side ----

  Future<List<Professional>> searchBaas({
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
    // Client-side safety net: hide any Baas the backend marked
    // inactive (offline toggle) even if the search query itself
    // didn't already filter them out server-side.
    return professionals.where((p) => p.active).toList();
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

  /// Returns the PayHere payment-object fields — feed straight into
  /// the PayHere mobile SDK's start-payment call.
  Future<Map<String, dynamic>> getPayHerePayment(String orderId) async {
    return _api.post('/api/orders/$orderId/payment/payhere');
  }

  Future<void> notifyPaymentFailed(String orderId) async {
    await _api.post('/api/orders/$orderId/payment-failed');
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
