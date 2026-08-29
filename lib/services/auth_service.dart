import 'api_client.dart';
import 'api_exception.dart';

enum AuthFlowType { login, register }

/// Result of [AuthService.requestOtp] — tells the UI whether this
/// number belongs to an existing account (straight to OTP -> done)
/// or is brand new (OTP -> then ask for a name, matching nameScreen
/// in the web apps).
class OtpRequestResult {
  final AuthFlowType flow;
  OtpRequestResult(this.flow);
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _api = ApiClient.instance;

  /// Mirrors the web apps' mobileContinue handler: try login first;
  /// a 404-shaped failure means the number is new, so fall through
  /// to registration instead. Any other failure re-throws as-is.
  Future<OtpRequestResult> requestOtp(String mobile) async {
    try {
      await _api.post('/api/auth/login', body: {'mobile': mobile}, auth: false);
      return OtpRequestResult(AuthFlowType.login);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _api.post('/api/auth/register/request-otp', body: {'mobile': mobile}, auth: false);
        return OtpRequestResult(AuthFlowType.register);
      }
      rethrow;
    }
  }

  /// For an existing account (flow == login). Saves the 7-day
  /// session token and returns the user map.
  Future<Map<String, dynamic>> verifyLoginOtp(String mobile, String otp) async {
    final data = await _api.post(
      '/api/auth/verify-otp',
      body: {'mobile': mobile, 'otp': otp},
      auth: false,
    );
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  /// For a brand new number (flow == register). Returns a short-lived
  /// (30 min) token — the caller must follow up with
  /// [completeRegistration] to set a name and get a full session,
  /// same as nameScreen does in the web apps.
  ///
  /// [role] should be 'baas' when called from the Baas app, and
  /// omitted (or 'customer') from the customer app — this is what
  /// flags the account correctly for every baas-only endpoint.
  Future<Map<String, dynamic>> verifyRegisterOtp(String mobile, String otp, {String? role}) async {
    final data = await _api.post(
      '/api/auth/register/verify-otp',
      body: {
        'mobile': mobile,
        'otp': otp,
        if (role != null) 'role': role,
      },
      auth: false,
    );
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  /// Finishes registration after verifyRegisterOtp — sets the name
  /// using the temporary token already saved, matching nameScreen's
  /// PUT /api/users/profile call in the web apps.
  Future<Map<String, dynamic>> completeRegistration({
    required String firstName,
    String? middleName,
    required String lastName,
  }) async {
    final data = await _api.put('/api/users/profile', body: {
      'firstName': firstName,
      if (middleName != null && middleName.isNotEmpty) 'middleName': middleName,
      'lastName': lastName,
    });
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveUser(user);
    return user;
  }

  /// Adds an email address to an account that doesn't have one yet -
  /// mirrors completeRegistration's PUT /api/users/profile pattern
  /// above, just with an email field instead of name fields. Not
  /// independently re-verified against the backend in this session;
  /// if this fails, that confirms the real contract for adding an
  /// email post-registration and this should be corrected.
  Future<Map<String, dynamic>> addEmail(String email) async {
    final data = await _api.put('/api/users/profile', body: {
      'email': email,
    });
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveUser(user);
    return user;
  }

  /// Customer app only — browse without a phone number. The backend
  /// blocks order creation with 428 MOBILE_REQUIRED until a real
  /// mobile is verified later (see requestOtp/verifyLoginOtp above,
  /// called again at that point to attach a number).
  Future<Map<String, dynamic>> guestRegister() async {
    final data = await _api.post('/api/auth/guest-register', body: {}, auth: false);
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  /// International path - mirrors requestOtp above but for email +
  /// GMAIL-delivered OTP instead of mobile + SMS, for accounts
  /// outside Sri Lanka (text.lk cannot reach international numbers).
  Future<OtpRequestResult> requestEmailOtp(String email) async {
    try {
      await _api.post('/api/auth/email/login', body: {'email': email}, auth: false);
      return OtpRequestResult(AuthFlowType.login);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _api.post('/api/auth/email/register/request-otp', body: {'email': email}, auth: false);
        return OtpRequestResult(AuthFlowType.register);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyEmailLoginOtp(String email, String otp) async {
    final data = await _api.post(
      '/api/auth/email/verify-otp',
      body: {'email': email, 'otp': otp},
      auth: false,
    );
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  /// [role] should be 'baas' when called from the Baas app, same
  /// convention as verifyRegisterOtp above.
  Future<Map<String, dynamic>> verifyEmailRegisterOtp(
    String email,
    String otp, {
    String? role,
    String? country,
    String? contactMobile,
  }) async {
    final data = await _api.post(
      '/api/auth/email/register/verify-otp',
      body: {
        'email': email,
        'otp': otp,
        if (role != null) 'role': role,
        if (country != null && country.isNotEmpty) 'country': country,
        if (contactMobile != null && contactMobile.isNotEmpty) 'contactMobile': contactMobile,
      },
      auth: false,
    );
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveToken(token);
    await _api.saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>?> refreshCurrentUser() async {
    final data = await _api.get('/api/users/me');
    final user = data['user'] as Map<String, dynamic>;
    await _api.saveUser(user);
    return user;
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() => _api.clearSession();
}
