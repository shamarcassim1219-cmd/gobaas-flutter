import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import 'otp_screen.dart';

/// A guest converting to a real account, or an existing account
/// logging back in. International (email) registration is not
/// offered here for now - only Sri Lankan mobile + SMS OTP.
///
/// [registrationRole] is set to 'baas' by the Baas app's copy of
/// this screen, left null (customer) here - see
/// AuthService.verifyRegisterOtp's `role` parameter for where this
/// actually gets used.
class LoginScreen extends StatefulWidget {
  final String? registrationRole;
  const LoginScreen({super.key, this.registrationRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  bool get _canContinue => RegExp(r'^07\d{8}$').hasMatch(_mobileController.text);

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AuthService.instance.requestOtp(_mobileController.text);
      if (!mounted) return;

      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: AppMotion.medium,
          pageBuilder: (_, animation, __) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: AppMotion.curve)),
            child: OtpScreen(
              mobile: _mobileController.text,
              isNewAccount: result.flow == AuthFlowType.register,
              registrationRole: widget.registrationRole,
              referralCode: _referralCodeController.text.trim(),
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Flutter shows a back arrow here automatically when this
      // screen was pushed on top of something (a guest tapping
      // "Login / Register"), and hides it automatically on the rare
      // case this is the very first screen shown.
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: BrandLogo(fontSize: 30)),
              const SizedBox(height: AppSpacing.xl),

              Text('Mobile Number', style: Theme.of(context).textTheme.titleMedium)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 4),
              Text(
                'Enter your 10-digit Sri Lankan mobile number.',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Text('+94', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(counterText: '', hintText: '07XXXXXXXX'),
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),

              const SizedBox(height: AppSpacing.lg),

              Text('Referral Code (Optional)', style: Theme.of(context).textTheme.titleMedium)
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 4),
              Text(
                'Have a code from a friend? Enter it here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 230.ms),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _referralCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'e.g. AB12CD'),
              ),

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canContinue && !_loading) ? _continue : null,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
