import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/orders_service.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';

/// Full detail for a single order - reached from anywhere an order
/// is referenced (Orders list, a review, a complaint, a wallet
/// transaction). Always fetches fresh from the backend by
/// [orderId], rather than trusting whatever partial copy of the
/// order the calling screen happened to have on hand.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  String? _error;
  MybaasOrder? _order;

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
      final order = await OrdersService.instance.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load this order. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Detail')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _order == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error ?? 'Order not found.', style: const TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      )
                    : _buildContent(_order!),
              ),
      ),
    );
  }

  Widget _buildContent(MybaasOrder order) {
    final (badgeColor, badgeBg) = _statusColors(order.status);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(order.service, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              child: Text(order.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: badgeColor)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(order.orderId, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontFamily: 'monospace')),
        const SizedBox(height: 24),

        _sectionCard([
          _row('Location', order.location),
          _row('Preferred Date', formatShortDate(DateTime.tryParse(order.preferredDate) ?? DateTime.now())),
          _row('Days', '${order.days} day${order.days == 1 ? '' : 's'}'),
          _row('Daily Rate', formatMoney(order.dailyRate, isInternational: false)),
          _row('Total', formatMoney(order.total, isInternational: false), emphasize: true),
        ]),

        if (order.professional != null) ...[
          const SizedBox(height: 16),
          Text('Baas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _sectionCard([
            _row('Name', order.professional!),
            if (order.professionalMobile != null && order.professionalMobile!.isNotEmpty)
              _row('Mobile', order.professionalMobile!),
          ]),
        ],

        const SizedBox(height: 16),
        Text('Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _sectionCard([
          _row('Method', order.paymentMethod == 'pay_now' ? 'Pay Now' : 'Pay Direct'),
          _row('Status', order.paymentStatus == 'PAID' ? 'Paid' : 'Pending'),
        ]),

        const SizedBox(height: 16),
        Text('Placed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _sectionCard([
          _row('Date', formatShortDate(order.createdAt)),
        ]),
      ],
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 16 : 13.5,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
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
