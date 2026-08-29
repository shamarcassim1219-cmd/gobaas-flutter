import 'package:flutter/material.dart';
import '../home/customer_home_screen.dart';

/// The logged-in app's root. Right now this just shows the customer
/// Home screen directly - once a bottom navigation bar (Home,
/// Orders, Wallet, Profile) and the Baas-side equivalent exist,
/// this is where that role-based branching and the nav bar itself
/// belong, so nothing calling `HomeShell()` has to change later.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: branch on the saved user's role (customer vs baas) once
    // a Baas-side home screen exists, and wrap both in a shared
    // bottom-nav Scaffold.
    return const CustomerHomeScreen();
  }
}
