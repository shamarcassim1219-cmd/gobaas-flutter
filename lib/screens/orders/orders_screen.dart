import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/orders_service.dart';
import '../../services/api_client.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../../localization/locale_controller.dart';

/// Mirrors the web apps' Activities/Orders page - every order the
/// customer has made, most recent first, with a status pill colored
/// by where it is in the lifecycle (Pending -> Awaiting Baas ->
/// Accepted -> Completed, or Cancelled/Rejected).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  String? _error;
  List<MybaasOrder> _orders = [];
  bool _isInternational = false;

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
      final user = await ApiClient.instance.getUser();
      final isInternational = user != null &&
          (user['mobile'] == null || (user['mobile'] as String).isEmpty) &&
          user['email'] != null &&
          (user['email'] as String).isNotEmpty;

      final orders = await OrdersService.instance.myOrders();

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isInternational = isInternational;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your orders. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t('myOrdersTitle'))),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _orders.isEmpty && _error == null
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
                          ..._orders.map(_buildOrderCard),
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
                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(t('noOrdersYet'), style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(MybaasOrder order) {
    final (badgeColor, badgeBg) = _statusColors(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.orderId, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                child: Text(
                  order.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _statusDescription(order.status),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(order.location, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (order.professional != null) ...[
            const SizedBox(height: 3),
            Text('Baas: ${order.professional}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.days} day${order.days == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              Text(
                formatMoney(order.total, isInternational: _isInternational),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'Pending':
        return 'Waiting for a Baas to be assigned';
      case 'Awaiting Baas':
        return 'Waiting for the Baas to accept your order';
      case 'Accepted':
        return 'The Baas has accepted - job in progress';
      case 'Completed':
        return 'This order is complete';
      case 'Cancelled':
        return 'This order was cancelled';
      case 'Rejected':
        return 'This order was declined by the Baas';
      default:
        return status;
    }
  }

  (Color, Color) _statusColors(String status) {
    switch (status) {
      case 'Completed':
        return (AppColors.success, AppColors.successSoft);
      case 'Accepted':
        return (AppColors.info, AppColors.infoSoft);
      case 'Cancelled':
      case 'Rejected':
        return (AppColors.danger, AppColors.dangerSoft);
      default:
        return (AppColors.warning, AppColors.warningSoft);
    }
  }
}
