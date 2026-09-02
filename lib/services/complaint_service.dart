import 'api_client.dart';

class Complaint {
  final String id;
  final String complaintId;
  final String orderId;
  final String professional;
  final String reason;
  final String details;
  final String status; // Pending | Approved | Rejected
  final String adminNote;
  final bool refunded;
  final double? refundAmount;
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.complaintId,
    required this.orderId,
    required this.professional,
    required this.reason,
    required this.details,
    required this.status,
    required this.adminNote,
    required this.refunded,
    this.refundAmount,
    required this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String? ?? '',
      complaintId: json['complaintId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      professional: json['professional'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      adminNote: json['adminNote'] as String? ?? '',
      refunded: json['refunded'] == true,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend: POST /api/complaints requires
/// orderId, reason, details, and accepts an optional photos array
/// (base64 strings) - only allowed for orders already Completed, one
/// active complaint per order. GET /api/complaints lists the
/// customer's own submissions.
class ComplaintService {
  ComplaintService._internal();
  static final ComplaintService instance = ComplaintService._internal();

  final _api = ApiClient.instance;

  Future<List<Complaint>> myComplaints() async {
    final data = await _api.get('/api/complaints');
    final list = (data['complaints'] as List?) ?? [];
    return list.map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submit({
    required String orderId,
    required String reason,
    required String details,
    List<String> photos = const [],
  }) async {
    await _api.post('/api/complaints', body: {
      'orderId': orderId,
      'reason': reason,
      'details': details,
      'photos': photos,
    });
  }
}
