import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/wallet_service.dart';
import '../../services/orders_service.dart';
import '../../services/notification_service.dart';
import '../../models/professional.dart';
import '../../utils/formatters.dart';
import '../../widgets/professional_card.dart';
import '../../localization/locale_controller.dart';
import '../orders/orders_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../hire/hire_screen.dart';
import '../baas_profile/baas_profile_screen.dart';
import '../support/live_chat_screen.dart';
import '../wallet/top_up_screen.dart';
import '../wallet/withdraw_screen.dart';
import '../reviews/my_reviews_screen.dart';
import '../../main.dart';

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

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _user;
  bool _isInternational = false;

  WalletBalance? _wallet;
  bool _walletLoading = true;

  int _unreadNotifications = 0;

  bool _searching = false;
  bool _searched = false;
  List<Professional> _results = [];
  String? _searchError;
  Timer? _searchExpiryTimer;

  // Canonical English values - must match exactly what the Baas app
  // stores in baasProfile.services, since the backend's /api/professionals
  // filter compares against these literally (case-insensitively).
  // null means "search all categories".
  String? _selectedCategory;

  static const _categories = [
    'Mason',
    'Carpenter',
    'Painter',
    'Electrician',
    'Plumber',
    'Welder',
    'Tiler',
    'Roofer',
    'General Labour',
  ];

  static const Map<String, String> _categoryLabelKeys = {
    'Mason': 'categoryMason',
    'Carpenter': 'categoryCarpenter',
    'Painter': 'categoryPainter',
    'Electrician': 'categoryElectrician',
    'Plumber': 'categoryPlumber',
    'Welder': 'categoryWelder',
    'Tiler': 'categoryTiler',
    'Roofer': 'categoryRoofer',
    'General Labour': 'categoryGeneralLabour',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUser();
    _loadWallet();
    _loadNotificationBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchExpiryTimer?.cancel();
    super.dispose();
  }

  /// Refreshes the wallet balance whenever the app comes back to the
  /// foreground - without this, returning to the app after a top-up
  /// completed elsewhere (or after some time away) would keep
  /// showing whatever balance was on screen when it was last
  /// backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWallet();
      _loadNotificationBadge();
    }
  }

  /// Search results reflect who was online and nearby at the moment
  /// of that search - a minute later, a Baas may have gone offline,
  /// accepted other work, or moved. Rather than keep showing that
  /// now-stale snapshot indefinitely, this clears it after a minute
  /// so the next look is always a fresh search, not old data mistaken
  /// for current.
  void _startSearchExpiryTimer() {
    _searchExpiryTimer?.cancel();
    _searchExpiryTimer = Timer(const Duration(minutes: 1), () {
      if (!mounted) return;
      setState(() {
        _searched = false;
        _results = [];
      });
    });
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
    if (await ApiClient.instance.isGuest()) {
      showLoginRequired(context);
      return;
    }

    final t = context.read<LocaleController>().t;

    _searchExpiryTimer?.cancel();

    setState(() {
      _searching = true;
      _searchError = null;
      // Clear whatever the previous search showed before this new
      // one runs - without this, a fresh search that comes back
      // empty (or errors) would leave the OLD results still on
      // screen underneath the new "No Baas Found" message, looking
      // like stale/wrong profiles rather than an empty result.
      _results = [];
      _searched = false;
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

      final (results, _) = await OrdersService.instance.searchBaas(
        lat: position.latitude,
        lng: position.longitude,
        radius: 30,
        service: _selectedCategory,
      );

      // Only ever show Baas who are currently online - the backend's
      // own offline-fallback list is deliberately not used here.
      final onlineOnly = results.where((p) => p.isOnline).toList();
      // Cheapest first, so the best-value options surface at the
      // top of the list.
      onlineOnly.sort((a, b) => a.price.compareTo(b.price));

      if (!mounted) return;
      setState(() {
        _results = onlineOnly;
        _searched = true;
        _searching = false;
      });
      _startSearchExpiryTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = t('noBaasFound');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;
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
                _buildHeader(t, firstName),
                const SizedBox(height: 20),
                _buildWalletCard(t),
                const SizedBox(height: 20),
                _buildQuickActions(t),
                const SizedBox(height: 24),
                _buildSearchSection(t),
                if (_searched) ...[
                  const SizedBox(height: 20),
                  _buildSearchResults(t),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String Function(String) t, String firstName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(t),
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ).then((_) => _loadNotificationBadge());
              },
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

  String _greeting(String Function(String) t) {
    final hour = DateTime.now().hour;
    if (hour < 12) return t('goodMorning');
    if (hour < 17) return t('goodAfternoon');
    return t('goodEvening');
  }

  Widget _buildWalletCard(String Function(String) t) {
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
          Text(
            t('walletBalance'),
            style: const TextStyle(
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
                label: t('topUp'),
                onTap: () async {
                  if (await ApiClient.instance.isGuest()) {
                    showLoginRequired(context);
                    return;
                  }
                  final completed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  );
                  if (completed == true) _loadWallet();
                },
              ),
              const SizedBox(width: 10),
              _walletActionButton(
                icon: Icons.arrow_outward,
                label: 'Withdraw',
                onTap: () async {
                  if (await ApiClient.instance.isGuest()) {
                    showLoginRequired(context);
                    return;
                  }
                  final completed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => WithdrawScreen(
                        availableBalance: _wallet?.available ?? 0,
                        isInternational: _isInternational,
                      ),
                    ),
                  );
                  if (completed == true) _loadWallet();
                },
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

  Widget _buildQuickActions(String Function(String) t) {
    final actions = [
      (Icons.receipt_long_outlined, 'myOrders'),
      (Icons.star_outline, 'reviews'),
      (Icons.support_agent_outlined, 'support'),
      (Icons.person_outline, 'profile'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        final (icon, key) = action;
        return Column(
          children: [
            InkWell(
              onTap: () => _handleQuickAction(key),
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
              t(key),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _handleQuickAction(String key) {
    switch (key) {
      case 'myOrders':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
        break;
      case 'profile':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case 'reviews':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
        break;
      case 'support':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveChatScreen()));
        break;
    }
  }

  Widget _buildSearchSection(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('needABaas'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t('needABaasDesc'),
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        const Text(
          'Searching within 30 km of your location',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          'Category',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3),
        ),
        const SizedBox(height: 8),
        _buildCategorySelector(t),
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
            label: Text(_searching ? t('searching') : t('searchNearMe')),
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

  String _selectedCategoryLabel(String Function(String) t) {
    if (_selectedCategory == null) return t('allCategories');
    return t(_categoryLabelKeys[_selectedCategory]!);
  }

  /// A tappable field that opens a full list of categories as a
  /// bottom sheet - replaces the earlier horizontal-scrolling chip
  /// row, which hid most categories off-screen until scrolled.
  Widget _buildCategorySelector(String Function(String) t) {
    return InkWell(
      onTap: () => _openCategoryPicker(t),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategoryLabel(t),
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker(String Function(String) t) async {
    final options = <String?>[null, ..._categories];

    final chosen = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('Category', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: options.map((category) {
                    final label = category == null ? t('allCategories') : t(_categoryLabelKeys[category]!);
                    final selected = _selectedCategory == category;
                    return ListTile(
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.accent : AppColors.textPrimary,
                        ),
                      ),
                      trailing: selected ? const Icon(Icons.check, color: AppColors.accent) : null,
                      onTap: () => Navigator.of(context).pop(category),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (chosen == _selectedCategory) return;
    setState(() => _selectedCategory = chosen);
  }

  Widget _buildSearchResults(String Function(String) t) {
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            t('noBaasFound'),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._results.map(
          (pro) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProfessionalCard(
              professional: pro,
              isInternational: _isInternational,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => HireScreen(professional: pro)),
                );
              },
              onViewProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BaasProfileScreen(professional: pro, isInternational: _isInternational)),
                );
              },
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.medium);
  }
}
