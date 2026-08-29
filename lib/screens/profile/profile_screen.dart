import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../localization/locale_controller.dart';
import '../onboarding/language_screen.dart';
import '../../main.dart';
import '../orders/orders_screen.dart';
import '../support/live_chat_screen.dart';
import '../about/about_screen.dart';

/// Mirrors the web apps' Profile page - account details (read-only
/// here for now) and Logout. Support and Reviews are separate rows
/// pointing at their own screens once those exist.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ApiClient.instance.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _logout() async {
    final t = context.read<LocaleController>().t;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('logout')),
        content: Text(t('logoutConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('logout'))),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.instance.logout();

    if (!mounted) return;

    // Unlock the language picker (was locked once a real account
    // loaded) and send them back to LanguageScreen - its Continue
    // button creates the fresh guest session after they pick a
    // language, same as first launch.
    context.read<LocaleController>().unlock();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: AppMotion.medium,
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const LanguageScreen()),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;

    final fullName = [
      _user?['firstName'] as String? ?? '',
      _user?['lastName'] as String? ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    final mobile = _user?['mobile'] as String? ?? '';
    final email = _user?['email'] as String? ?? '';
    final isInternational = mobile.isEmpty && email.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t('profile'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName.isNotEmpty ? fullName : 'GOBAAS User',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  if (isInternational) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.infoSoft,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        '🌍 ${t('international')}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.info),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (mobile.isEmpty && email.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('guestBrowsing'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('guestBrowsingDesc'),
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => showLoginRequired(context),
                        child: Text(t('loginRegister')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _sectionCard([
              _infoRow(Icons.phone_outlined, t('mobile'), mobile.isNotEmpty ? mobile : t('notSet')),
              _infoRow(Icons.email_outlined, t('email'), email.isNotEmpty ? email : t('notSet')),
            ]),
            const SizedBox(height: 16),
            _sectionCard([
              _actionRow(Icons.star_outline, t('myReviews'), () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
              }),
              _actionRow(Icons.support_agent_outlined, t('support'), () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveChatScreen()));
              }),
              _actionRow(Icons.info_outline, t('aboutGobaas'), () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
              }),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
                label: Text(t('logout'), style: const TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dangerSoft, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
