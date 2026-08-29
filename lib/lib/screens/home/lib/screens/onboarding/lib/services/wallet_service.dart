import 'api_client.dart';

class WalletBalance {
  final double available;
  final double pending;
  final double withdrawing;
  final double total;

  WalletBalance({
    required this.available,
    required this.pending,
    required this.withdrawing,
    required this.total,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      available: (json['available'] as num?)?.toDouble() ?? 0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0,
      withdrawing: (json['withdrawing'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LedgerEntry {
  final String type;
  final double amount;
  final String state;
  final String note;
  final DateTime createdAt;
