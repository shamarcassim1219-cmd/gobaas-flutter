import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../utils/formatters.dart';
import '../../localization/locale_controller.dart';
import '../orders/orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../reviews/my_reviews_screen.dart';
import '../support/live_chat_screen.dart';
import '../complaints/my_complaints_screen.dart';

/// Mirrors the web apps' Notifications page - unread ones visually
/// distinct, tap to mark read, with an icon per type so the list is
/// scannable at a glance (order updates vs payment vs account vs
/// support).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<MybaasNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await NotificationService.instance.list();
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load notifications. Pull down to try again.';
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.instance.markAllRead();
      await _load();
    } catch (_) {
      // Silent - not critical enough to interrupt the person over.
    }
  }

  Future<void> _onTapNotification(MybaasNotification notification) async {
    if (!notification.read) {
      try {
        await NotificationService.instance.markRead(notification.id);
        if (mounted) {
          setState(() {
            final index = _notifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _notifications[index] = MybaasNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                type: notification.type,
                data: notification.data,
                read: true,
                createdAt: notification.createdAt,
              );
            }
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    switch (notification.type) {
      case 'order':
      case 'payment_failed':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
        break;
      case 'payment':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen()));
        break;
      case 'complaint':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyComplaintsScreen()));
        break;
      case 'review':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
        break;
      case 'support':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveChatScreen()));
        break;
      case 'security':
      case 'account':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      default:
        // 'plain' or anything unrecognized - nothing further to
        // navigate to, the message itself was the whole point.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;
    final hasUnread = _notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('notificationsTitle')),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(t('markAllRead')),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _notifications.isEmpty && _error == null
                    ? _buildEmptyState(t)
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            ),
                          ..._notifications.map(_buildNotificationCard),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(t('noNotificationsYet'), style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(MybaasNotification notification) {
    return InkWell(
      onTap: () => _onTapNotification(notification),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.read ? AppColors.surface : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: notification.read ? AppColors.border : AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(notification.type), size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.read ? FontWeight.w600 : FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatShortDate(notification.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'payment':
      case 'payment_failed':
        return Icons.account_balance_wallet_outlined;
      case 'review':
        return Icons.star_outline;
      case 'support':
        return Icons.support_agent_outlined;
      case 'security':
        return Icons.shield_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
