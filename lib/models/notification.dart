class MybaasNotification {
  final String id;
  final String title;
  final String message;
  final String type; // order | payment | payment_failed | security | account | review | support
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  MybaasNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  /// For payment_failed notifications, the order to resume payment for.
  String? get orderId => data['orderId'] as String?;

  factory MybaasNotification.fromJson(Map<String, dynamic> json) {
    return MybaasNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'account',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
