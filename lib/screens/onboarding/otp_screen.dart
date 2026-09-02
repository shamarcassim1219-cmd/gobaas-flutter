import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../services/push_notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import 'name_screen.dart';
import '../home/home_shell.dart';

class OtpScreen extends StatefulWidget {
  final String? mobile;
  final String? email;
  final String? country;
  final bool isNewAccount;
  final String? registrationRole;
  final String? referralCode;

  const OtpScreen({
    super.key,
    this.mobile,
    this.email,
    this.country,
    required this.isNewAccount,
    this.registrationRole,
    this.referralCode,
  });

  bool get isEmailFlow => email != null;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _wrong = false;
  String? _error;

  bool _resending = false;
  int _resendCooldown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;

    setState(() {
      _resending = true;
      _error = null;
    });

    try {
      widget.isEmailFlow
          ? await AuthService.instance.requestEmailOtp(widget.email!)
          : await AuthService.instance.requestOtp(widget.mobile!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent again.')),
      );
      _startResendCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() {
      _loading = true;
      _wrong = false;
      _error = null;
    });

    try {
      Map<String, dynamic> user;

      if (widget.isEmailFlow) {
        user = widget.isNewAccount
            ? await AuthService.instance.verifyEmailRegisterOtp(
                widget.email!,
                otp,
                role: widget.registrationRole,
                country: widget.country,
                referralCode: widget.referralCode,
              )
            : await AuthService.instance.verifyEmailLoginOtp(widget.email!, otp);
      } else {
        user = widget.isNewAccount
            ? await AuthService.instance.verifyRegisterOtp(
                widget.mobile!,
                otp,
                role: widget.registrationRole,
                referralCode: widget.referralCode,
              )
            : await AuthService.instance.verifyLoginOtp(widget.mobile!, otp);
      }

      if (!mounted) return;

      // Re-associate this device's push token with whichever account
      // just logged in/registered - matters most when a different
      // account logs in on a device that was previously signed into
      // someone else's.
      PushNotificationService.instance.initialize();

      if (widget.isNewAccount) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: AppMotion.medium,
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const NameScreen()),
          ),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: AppMotion.slow,
            pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const HomeShell()),
          ),
          (route) => false,
        );
      }

      // user map intentionally unused here beyond triggering the
      // navigation above - HomeShell/NameScreen re-read the saved
      // session themselves on build.
      user;
    } on ApiException catch (e) {
      setState(() {
        _wrong = true;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _wrong = true;
        _error = 'Invalid code. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.isEmailFlow ? widget.email! : '+94 ${widget.mobile}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Center(child: BrandLogo(fontSize: 26)),
              const SizedBox(height: AppSpacing.lg),
              Text('Enter verification code', style: Theme.of(context).textTheme.headlineMedium)
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              Text(
                'We sent a code to $destination',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 180.ms),
              const SizedBox(height: AppSpacing.xl),

              Center(
                child: _OtpBoxes(
                  controller: _otpController,
                  isWrong: _wrong,
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 6) _verify();
                  },
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Center(
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_otpController.text.length == 6 && !_loading) ? _verify : null,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                        )
                      : const Text('Verify'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        'Resend code in ${_resendCooldown}s',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: _resending
                            ? const SizedBox(
                                height: 16, width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Resend Code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six individual animated boxes rather than a single text field -
/// reads immediately as "this is an OTP input" and gives a small,
/// satisfying pop as each digit lands.
class _OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final bool isWrong;
  final ValueChanged<String> onChanged;

  const _OtpBoxes({required this.controller, required this.isWrong, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final filled = index < controller.text.length;
            final digit = filled ? controller.text[index] : '';

            return Container(
              width: 44,
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: filled ? AppColors.accentSoft : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isWrong
                      ? AppColors.danger
                      : (filled ? AppColors.accent : AppColors.border),
                  width: filled || isWrong ? 2 : 1.5,
                ),
              ),
              child: Text(
                digit,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            )
                .animate(target: filled ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 120.ms)
                .then()
                .scale(begin: const Offset(1.06, 1.06), end: const Offset(1, 1), duration: 120.ms);
          }),
        )
            .animate(target: isWrong ? 1 : 0)
            .shake(hz: 4, duration: 400.ms, curve: Curves.easeInOut),

        // Invisible field that actually captures input/keyboard.
        Opacity(
          opacity: 0,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            autofocus: true,
          ),
        ),
      ],
    );
  }
}
