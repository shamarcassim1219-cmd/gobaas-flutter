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

  LedgerEntry({
    required this.type,
    required this.amount,
    required this.state,
    required this.note,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      state: json['state'] as String? ?? 'available',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class WalletService {
  WalletService._internal();
  static final WalletService instance = WalletService._internal();

  final _api = ApiClient.instance;

  /// Confirmed against the real backend: GET /api/wallet ->
  /// {wallet: {available, pending, withdrawing, total}, ledger: [...]}
  Future<(WalletBalance, List<LedgerEntry>)> load() async {
    final data = await _api.get('/api/wallet');
    final balance = WalletBalance.fromJson(data['wallet'] as Map<String, dynamic>? ?? {});
    final ledgerRaw = (data['ledger'] as List?) ?? [];
    final ledger = ledgerRaw.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
    return (balance, ledger);
  }

  /// Confirmed against the real backend: POST /api/wallet/withdrawals
  /// requires bankName, accountName, accountNumber (branch is
  /// optional) - a single free-text field is not accepted. Minimum
  /// withdrawal is Rs. 1,000.
  Future<void> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? branch,
  }) async {
    await _api.post('/api/wallet/withdrawals', body: {
      'amount': amount,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      if (branch != null && branch.isNotEmpty) 'branch': branch,
    });
  }

  /// Confirmed against the real backend: POST /api/wallet/payhere/create
  /// returns a flat object (orderId, amount, currency, notify_url,
  /// merchantId, hash, sandbox, firstName, lastName, email, phone,
  /// address, city, country) - camelCase, not the snake_case PayHere's
  /// JS SDK expects, and it does not include return_url/cancel_url/
  /// items (PayHereWebViewScreen builds those itself when mapping
  /// this response into the actual payhere.startPayment() object).
  /// Minimum top-up is Rs. 100.
  Future<Map<String, dynamic>> createPayHereTopUp(double amount) async {
    final data = await _api.post('/api/wallet/payhere/create', body: {
      'amount': amount,
    });
    return data;
  }
}
