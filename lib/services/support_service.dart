import 'api_client.dart';

/// NOTE: endpoint path/payload inferred from the general "Support"
/// concept referenced elsewhere in this project (complaint threads,
/// live chat, managed from the admin panel) - not independently
/// re-verified against the backend in this session. If this 404s,
/// that confirms the real endpoint and this should be corrected.
class SupportService {
  SupportService._internal();
  static final SupportService instance = SupportService._internal();

  final _api = ApiClient.instance;

  Future<void> submitRequest({
    required String subject,
    required String message,
  }) async {
    await _api.post('/api/support', body: {
      'subject': subject,
      'message': message,
    });
  }
}
