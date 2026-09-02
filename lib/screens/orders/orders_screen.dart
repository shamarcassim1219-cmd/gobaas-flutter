import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/orders_service.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../services/api_exception.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../../localization/locale_controller.dart';
import '../complaints/complaint_screen.dart';

/// Mirrors the web apps' Activities/Orders page - every order the
/// customer has made, most recent first, with a status pill colored
/// by where it is in the lifecycle (Pending -> Awaiting Baas ->
/// Accepted -> Completed, or Cancelled/Rejected). Tapping a
/// Completed order opens the review dialog directly, rather than a
/// separate Reviews screen - one less navigation step, and one less
/// place for a data-loading edge case to slip through.
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

  // Tracks orders reviewed during this session - the order model
  // doesn't carry an "already reviewed" flag from the backend, so
  // this is a best-effort limit to one review per order per visit
  // rather than a permanent one enforced across app restarts.
  final Set<String> _reviewedOrderIds = {};

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

  Future<void> _showCompletedOrderOptions(MybaasOrder order, bool alreadyReviewed) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alreadyReviewed)
              ListTile(
                leading: const Icon(Icons.star_outline, color: AppColors.primary),
                title: const Text('Leave a Review'),
                onTap: () => Navigator.of(context).pop('review'),
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
              title: const Text('Report a Problem'),
              onTap: () => Navigator.of(context).pop('complaint'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'review') {
      _openReviewDialog(order);
    } else if (choice == 'complaint') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComplaintScreen(order: order)));
    }
  }

  Future<void> _openReviewDialog(MybaasOrder order) async {
    if (_reviewedOrderIds.contains(order.id)) return;

    int rating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Review ${order.professional ?? 'the Baas'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return GestureDetector(
                    onTap: () => setDialogState(() => rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        starValue <= rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await ReviewService.instance.submitReview(
        orderId: order.orderId,
        rating: rating,
        comment: commentController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _reviewedOrderIds.add(order.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        // Already reviewed (backend enforces this too) - treat the
        // same as a successful local mark so the UI stops offering
        // to review it again.
        setState(() => _reviewedOrderIds.add(order.id));
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit your review. Please try again.')),
      );
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
    final isCompleted = order.status == 'Completed';
    final alreadyReviewed = _reviewedOrderIds.contains(order.id);

    return InkWell(
      onTap: isCompleted ? () => _showCompletedOrderOptions(order, alreadyReviewed) : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
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
            if (_shouldShowBaasPhone(order)) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.phone, size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    order.professionalMobile!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ],
              ),
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
            if (isCompleted) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    alreadyReviewed ? Icons.check_circle : Icons.star_outline,
                    size: 15,
                    color: alreadyReviewed ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alreadyReviewed ? 'Reviewed · Tap for more options' : 'Tap to review or report a problem',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: alreadyReviewed ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Confirmed against the real backend: the assigned Baas's mobile
  /// number is already present on the order object from creation
  /// (professionalMobile) - this just decides when it's actually
  /// relevant to reveal it to the customer, rather than showing a
  /// contact number before there's any reason to use it. For
  /// pay_direct, that's once the Baas has accepted (so the customer
  /// can reach them to arrange in-person payment); for pay_now,
  /// that's once payment has actually gone through.
  bool _shouldShowBaasPhone(MybaasOrder order) {
    if (order.professionalMobile == null || order.professionalMobile!.isEmpty) return false;

    if (order.paymentMethod == 'pay_direct') {
      return order.status == 'Accepted' || order.status == 'Completed';
    }

    if (order.paymentMethod == 'pay_now') {
      return order.paymentStatus == 'PAID';
    }

    return false;
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
