import 'api_client.dart';

class ReferralInfo {
  final String referralCode;
  final int referredCount;
  final double totalEarnings;

  ReferralInfo({
    required this.referralCode,
    required this.referredCount,
    required this.totalEarnings,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      referralCode: json['referralCode'] as String? ?? '',
      referredCount: (json['referredCount'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Confirmed against the real backend: GET /api/referral/info ->
/// {success, referralCode, referredCount, totalEarnings} - the
/// backend lazily generates a referralCode for the account on
/// first call if it doesn't have one yet (covers accounts created
/// before this feature existed).
class ReferralService {
  ReferralService._internal();
  static final ReferralService instance = ReferralService._internal();

  final _api = ApiClient.instance;

  Future<ReferralInfo> load() async {
    final data = await _api.get('/api/referral/info');
    return ReferralInfo.fromJson(data);
  }
}
