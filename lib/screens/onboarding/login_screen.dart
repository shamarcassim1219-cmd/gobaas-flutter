import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import 'otp_screen.dart';

const _countries = [
  ('United States', '🇺🇸', '+1'),
  ('United Kingdom', '🇬🇧', '+44'),
  ('Canada', '🇨🇦', '+1'),
  ('Australia', '🇦🇺', '+61'),
  ('India', '🇮🇳', '+91'),
  ('United Arab Emirates', '🇦🇪', '+971'),
  ('Qatar', '🇶🇦', '+974'),
  ('Saudi Arabia', '🇸🇦', '+966'),
  ('Kuwait', '🇰🇼', '+965'),
  ('Singapore', '🇸🇬', '+65'),
  ('Malaysia', '🇲🇾', '+60'),
  ('Germany', '🇩🇪', '+49'),
  ('France', '🇫🇷', '+33'),
  ('Italy', '🇮🇹', '+39'),
  ('Netherlands', '🇳🇱', '+31'),
  ('New Zealand', '🇳🇿', '+64'),
  ('Japan', '🇯🇵', '+81'),
  ('South Korea', '🇰🇷', '+82'),
  ('Maldives', '🇲🇻', '+960'),
  ('Other', '🌍', ''),
];

/// Set to 'baas' by the Baas app's copy of this screen, left null
/// (customer) here - see AuthService.verify*RegisterOtp's `role`
/// parameter for where this actually gets used.
class LoginScreen extends StatefulWidget {
  final String? registrationRole;
  const LoginScreen({super.key, this.registrationRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedCountry;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isMobileTab => _tabController.index == 0;

  bool get _canContinue {
    if (_isMobileTab) {
      return RegExp(r'^07\d{8}$').hasMatch(_mobileController.text);
    }
    final emailOk = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim());
    return emailOk && _selectedCountry != null;
  }

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isMobileTab) {
        final result = await AuthService.instance.requestOtp(_mobileController.text);
        if (!mounted) return;
        _goToOtp(mobile: _mobileController.text, isNew: result.flow == AuthFlowType.register);
      } else {
        final result = await AuthService.instance.requestEmailOtp(_emailController.text.trim());
        if (!mounted) return;
        _goToOtp(
          email: _emailController.text.trim(),
          country: _selectedCountry,
          isNew: result.flow == AuthFlowType.register,
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToOtp({String? mobile, String? email, String? country, required bool isNew}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.medium,
        pageBuilder: (_, animation, __) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: AppMotion.curve)),
          child: OtpScreen(
            mobile: mobile,
            email: email,
            country: country,
            isNewAccount: isNew,
            registrationRole: widget.registrationRole,
          ),
        ),
      ),
    );
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

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (_) => setState(() {}),
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: AppShadows.card,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  tabs: const [
                    Tab(text: 'Sri Lanka'),
                    Tab(text: 'International'),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: AppSpacing.xl),

              AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: _isMobileTab ? _buildMobileForm() : _buildEmailForm(),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
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

  Widget _buildMobileForm() {
    return Column(
      key: const ValueKey('mobile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile Number', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Enter your 10-digit Sri Lankan mobile number.', style: Theme.of(context).textTheme.bodyMedium),
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
      ],
    );
  }

  Widget _buildEmailForm() {
    final dialCode = _selectedCountry == null
        ? ''
        : _countries.firstWhere((c) => c.$1 == _selectedCountry, orElse: () => _countries.last).$3;

    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Address', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text("We'll send you a verification code.", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'you@example.com'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Country', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCountry,
          isExpanded: true,
          decoration: const InputDecoration(),
          hint: const Text('Select your country'),
          items: _countries
              .map((c) => DropdownMenuItem(value: c.$1, child: Text('${c.$2}  ${c.$1}')))
              .toList(),
          onChanged: (value) => setState(() => _selectedCountry = value),
        ),
        if (dialCode.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dial code: $dialCode',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
