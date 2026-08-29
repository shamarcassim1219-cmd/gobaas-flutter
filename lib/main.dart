import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/home/home_shell.dart';

/// This file intentionally stays minimal — it proves the foundation
/// (ApiClient, AuthService, models) wires together and boots, the
/// same way each web app's "APP START" block just checks for a
/// token and picks a screen. Real screens (home, search, hire flow,
/// wallet...) get built out from here next; onboarding is already
/// wired below.
void main() {
  runApp(const MybaasApp());
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

/// Mirrors the web apps' guest-browsing pattern: no language/login
/// screen up front at all - the app opens straight into a guest
/// session (a real, if temporary, account created automatically),
/// and a real login/register is only ever asked for later, right
/// when a guest tries to do something that actually needs a
/// verified identity (see HireScreen's MOBILE_REQUIRED handling).
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareSession();
  }

  Future<void> _prepareSession() async {
    try {
      final alreadyLoggedIn = await AuthService.instance.isLoggedIn();

      if (!alreadyLoggedIn) {
        // First launch, or a previous session was cleared - start a
        // guest session automatically rather than blocking on a
        // language/login screen nobody asked for yet.
        await AuthService.instance.guestRegister();
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
