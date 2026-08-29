import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/home/customer_home_screen.dart';

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

/// Equivalent of each web app's closing "APP START" IIFE:
/// token present -> go straight in; none -> show the language/
/// get-started flow.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppTheme.light.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedIn) {
      // TODO: once BaasHomeScreen exists, branch on the stored
      // user's role the same way - for now only the customer side
      // routes to a real screen.
      return const CustomerHomeScreen();
    }

    return const LanguageScreen();
  }
}
