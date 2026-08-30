class MybaasOrder {
  final String id;
  final String orderId;
  final String service;
  final String location;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int days;
  final double dailyRate;
  final double total;
  final String preferredDate;
  final String status; // Pending | Awaiting Baas | Accepted | Completed | Cancelled | Rejected
  final String paymentMethod; // pay_now | pay_direct
  final String paymentStatus; // PAID | PENDING
  final String? professional; // Baas name, once assigned
  final String? professionalId;
  final String? professionalMobile; // confirmed against the real backend - present on the order from creation, shown to the customer once it's actually relevant (see OrdersScreen)
  final String? customerName; // only present on baas-side "active"/"completed" views
  final String? customerMobile;
  final bool directRequest;
  final DateTime createdAt;

  MybaasOrder({
    required this.id,
    required this.orderId,
    required this.service,
    required this.location,
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.days,
    required this.dailyRate,
    required this.total,
    required this.preferredDate,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.professional,
    this.professionalId,
    this.professionalMobile,
    this.customerName,
    this.customerMobile,
    this.directRequest = false,
    required this.createdAt,
  });

  factory MybaasOrder.fromJson(Map<String, dynamic> json) {
    return MybaasOrder(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      service: json['service'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      days: (json['days'] as num?)?.toInt() ?? 1,
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      preferredDate: json['preferredDate'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      professional: json['professional'] as String?,
      professionalId: json['professionalId'] as String?,
      professionalMobile: json['professionalMobile'] as String?,
      customerName: json['customerName'] as String?,
      customerMobile: json['customerMobile'] as String?,
      directRequest: json['directRequest'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
