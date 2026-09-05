import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../localization/locale_controller.dart';
import 'customer_home_screen.dart';
import '../orders/orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

/// Four-tab shell: Home (search + wallet summary), Orders, Wallet,
/// Settings - mirrors the Baas app's own HomeShell/HomeDashboard
/// structure, so both apps navigate the same way even though their
/// tab content differs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _homeKey = GlobalKey<CustomerHomeScreenState>();
  final _ordersKey = GlobalKey<OrdersScreenState>();
  final _walletKey = GlobalKey<WalletScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _tabs = [
    CustomerHomeScreen(key: _homeKey),
    OrdersScreen(key: _ordersKey),
    WalletScreen(key: _walletKey),
    ProfileScreen(key: _profileKey),
  ];

  void _onTap(int index) {
    setState(() => _index = index);
    // IndexedStack keeps every tab's State alive but doesn't rebuild
    // it on switch, so a change made on one tab (a top-up on Home, a
    // mobile change on Settings) wouldn't otherwise show up on
    // another tab until it's manually pulled to refresh.
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _ordersKey.currentState?.refresh();
        break;
      case 2:
        _walletKey.currentState?.refresh();
        break;
      case 3:
        _profileKey.currentState?.refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_outlined), activeIcon: const Icon(Icons.receipt_long), label: t('myOrders')),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined), activeIcon: const Icon(Icons.account_balance_wallet), label: t('wallet')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: t('profile')),
        ],
      ),
    );
  }
}
