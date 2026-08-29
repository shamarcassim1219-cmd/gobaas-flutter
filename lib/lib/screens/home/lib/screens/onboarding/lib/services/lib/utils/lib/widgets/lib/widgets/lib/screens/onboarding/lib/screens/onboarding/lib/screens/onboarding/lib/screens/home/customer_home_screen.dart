import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/wallet_service.dart';
import '../../services/orders_service.dart';
import '../../services/notification_service.dart';
import '../../models/professional.dart';
import '../../utils/formatters.dart';
import '../../widgets/professional_card.dart';

/// The customer's landing screen after login - mirrors the web
/// app's Home page: greeting, wallet balance, quick actions, and an
/// inline "search nearby Baas" flow that shows results right on
/// this same screen once results come back (same UX decision the
/// web app made: no separate scanning/results screen).
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  Map<String, dynamic>? _user;
  bool _isInternational = false;

  WalletBalance? _wallet;
  bool _walletLoading = true;

  int _unreadNotifications = 0;

  bool _searching = false;
  bool _searched = false;
  List<Professional> _results = [];
  bool _usedOfflineFallback = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadWallet();
    _loadNotificationBadge();
  }

  Future<void> _loadUser() async {
    final user = await ApiClient.instance.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isInternational = user != null &&
          (user['mobile'] == null || (user['mobile'] as String).isEmpty) &&
          user['email'] != null &&
          (user['email'] as String).isNotEmpty;
    });
  }

  Future<void> _loadWallet() async {
    try {
      final (balance, _) = await WalletService.instance.load();
      if (!mounted) return;
      setState(() {
        _wallet = balance;
        _walletLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _walletLoading = false);
    }
  }

  Future<void> _loadNotificationBadge() async {
    try {
      final count = await NotificationService.instance.unreadCount();
      if (!mounted) return;
      setState(() => _unreadNotifications = count);
    } catch (_) {
      // Badge just stays at 0 - not worth surfacing an error for.
    }
  }

  Future<void> _startSearch() async {
    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;

      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }

      if (granted == LocationPermission.denied ||
          granted == LocationPermission.deniedForever) {
        setState(() {
          _searching = false;
          _searchError = 'Location permission is needed to find nearby Baas.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final results = await OrdersService.instance.searchBaas(
        lat: position.latitude,
        lng: position.longitude,
        radius: 30,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = 'Unable to search right now. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (_user?['firstName'] as String?) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([_loadWallet(), _loadNotificationBadge()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(firstName),
                const SizedBox(height: 20),
                _buildWalletCard(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSearchSection(),
                if (_searched) ...[
                  const SizedBox(height: 20),
                  _buildSearchResults(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName.isNotEmpty ? firstName : 'there',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, size: 26),
              color: AppColors.textPrimary,
            ),
            if (_unreadNotifications > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildWalletCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WALLET BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _walletLoading
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  formatMoney(_wallet?.available ?? 0, isInternational: _isInternational),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: [
              _walletActionButton(
                icon: Icons.add,
                label: 'Top Up',
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _walletActionButton(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.medium).slideY(
          begin: 0.08,
          end: 0,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
        );
  }

  Widget _walletActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.receipt_long_outlined, 'My Orders'),
      (Icons.star_outline, 'Reviews'),
      (Icons.support_agent_outlined, 'Support'),
      (Icons.person_outline, 'Profile'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        final (icon, label) = action;
        return Column(
          children: [
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need a Baas?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Search verified professionals near you.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _searching ? null : _startSearch,
            icon: _searching
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.search),
            label: Text(_searching ? 'Searching...' : 'Search Baas Near Me'),
          ),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Text(
            _searchError!,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No Baas found nearby right now.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_usedOfflineFallback)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Nearby Baas (currently offline - may respond later)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ..._results.map(
          (pro) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProfessionalCard(
              professional: pro,
              isInternational: _isInternational,
              onTap: () {},
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.medium);
  }
}
