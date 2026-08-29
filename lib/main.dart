import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'localization/locale_controller.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/home/home_shell.dart';

/// This file intentionally stays minimal — it proves the foundation
/// (ApiClient, AuthService, models) wires together and boots, the
/// same way each web app's "APP START" block just checks for a
/// token and picks a screen. Real screens (home, search, hire flow,
/// wallet...) get built out from here next; onboarding is already
/// wired below.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleController(),
      child: const MybaasApp(),
    ),
  );
}

class MybaasApp extends StatelessWidget {
  const MybaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOBAAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _StartupGate(),
    );
  }
}

/// First launch (no session at all yet): shows LanguageScreen, whose
/// Continue button creates a guest account automatically - there is
/// no separate "login" step just to browse. Any later launch, once
/// a session (guest or real) already exists, skips straight to
/// HomeShell. A real login/register is only ever asked for later,
/// right when a guest tries to do something that actually needs a
/// verified identity (see HireScreen's MOBILE_REQUIRED handling).
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _needsLanguageScreen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  Future<void> _prepareSession() async {
    try {
      final locale = context.read<LocaleController>();
      await locale.load();

      final alreadyLoggedIn = await AuthService.instance.isLoggedIn();

      if (!alreadyLoggedIn) {
        // Truly first launch - let LanguageScreen's Continue button
        // create the guest session, after the person has picked a
        // language.
        if (!mounted) return;
        setState(() {
          _needsLanguageScreen = true;
          _ready = true;
        });
        return;
      }

      // A session already exists - a real (non-guest) account locks
      // the language picker, forcing English for international ones.
      final user = await ApiClient.instance.getUser();
      final isInternational = user != null &&
          (user['mobile'] == null || (user['mobile'] as String).isEmpty) &&
          user['email'] != null &&
          (user['email'] as String).isNotEmpty;

      if (user != null && (user['mobile'] != null || user['email'] != null)) {
        await locale.lockForAccount(isInternational: isInternational);
      }

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to connect. Please check your internet connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _prepareSession();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsLanguageScreen) {
      return const LanguageScreen();
    }

    return const HomeShell();
  }
}

/// Exposed so any screen can redirect a guest here the moment they
/// try something that actually needs a real, verified account -
/// e.g. HireScreen catching a MOBILE_REQUIRED error. Kept in
/// main.dart since _StartupGate above is the only other place that
/// currently decides between LoginScreen and HomeShell.
void showLoginRequired(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}
