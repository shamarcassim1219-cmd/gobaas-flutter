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

  /// Mirrors GET /api/wallet used identically by both web apps -
  /// same endpoint serves a customer's or a Baas's own wallet,
  /// scoped server-side by the auth token.
  Future<(WalletBalance, List<LedgerEntry>)> load() async {
    final data = await _api.get('/api/wallet');
    final balance = WalletBalance.fromJson(data['wallet'] as Map<String, dynamic>? ?? {});
    final ledgerRaw = (data['ledger'] as List?) ?? [];
    final ledger = ledgerRaw.map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>)).toList();
    return (balance, ledger);
  }

  /// NOTE: endpoint path/payload here is inferred from the admin
  /// side's GET /api/wallet/withdrawals (which lists requests) and
  /// WalletBalance already tracking a `withdrawing` amount - not
  /// independently re-verified against the backend in this session.
  /// If this 404s or the payload shape is wrong, that confirms the
  /// real contract and this should be corrected to match it.
  Future<void> requestWithdrawal({
    required double amount,
    required String accountDetails,
  }) async {
    await _api.post('/api/wallet/withdrawals', body: {
      'amount': amount,
      'accountDetails': accountDetails,
    });
  }

  /// Creates a PENDING wallet top-up transaction server-side and
  /// returns the PayHere Checkout API fields (merchant_id, order_id,
  /// hash, amount, currency, items, first_name, last_name, email,
  /// phone, address, city, country, return_url, cancel_url,
  /// notify_url) to feed straight into payhere.startPayment() in the
  /// WebView. Mirrors POST /api/wallet/payhere/create used by the
  /// web apps' own wallet top-up flow - not independently
  /// re-verified in this session, so if a field the WebView expects
  /// is missing from the response, that confirms the real shape.
  Future<Map<String, dynamic>> createPayHereTopUp(double amount) async {
    final data = await _api.post('/api/wallet/payhere/create', body: {
      'amount': amount,
    });
    return data['payment'] as Map<String, dynamic>? ?? data;
  }
}
