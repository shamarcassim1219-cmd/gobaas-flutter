import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/orders_service.dart';
import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../models/professional.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../../localization/locale_controller.dart';
import '../orders/orders_screen.dart';
import '../wallet/payhere_webview_screen.dart';
import '../../main.dart';

/// Mirrors the web apps' hire form - shown after tapping a search
/// result. Location, number of days, a preferred date, and payment
/// method (pay now vs pay the Baas directly), with the total
/// recalculated live as days changes. Submits via
/// OrdersService.createOrder, same as the web apps' hire button.
/// For pay_now orders, follows up by letting the customer choose
/// wallet balance or card (PayHere) to actually settle it.
class HireScreen extends StatefulWidget {
  final Professional professional;

  const HireScreen({super.key, required this.professional});

  @override
  State<HireScreen> createState() => _HireScreenState();
}

class _HireScreenState extends State<HireScreen> {
  final _locationController = TextEditingController();
  int _days = 1;
  DateTime? _preferredDate;
  String _paymentMethod = 'pay_direct'; // 'pay_now' | 'pay_direct'

  bool _submitting = false;
  String? _error;
  bool _isInternational = false;

  @override
  void initState() {
    super.initState();
    _checkAccountType();
  }

  Future<void> _checkAccountType() async {
    final user = await ApiClient.instance.getUser();
    if (!mounted) return;
    setState(() {
      _isInternational = user != null &&
          (user['mobile'] == null || (user['mobile'] as String).isEmpty) &&
          user['email'] != null &&
          (user['email'] as String).isNotEmpty;
    });
  }

  double get _total => widget.professional.price * _days;

  bool get _canSubmit => _locationController.text.trim().isNotEmpty && _preferredDate != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final t = context.read<LocaleController>().t;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final order = await OrdersService.instance.createOrder(
        service: widget.professional.service,
        professionalId: widget.professional.id,
        professionalName: widget.professional.name,
        location: _locationController.text.trim(),
        days: _days,
        dailyRate: widget.professional.price,
        preferredDate: _preferredDate!.toIso8601String(),
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;

      if (_paymentMethod == 'pay_now') {
        await _choosePaymentMethod(order);
      } else {
        _showOrderCreatedDialog(t, payNow: false);
      }
    } on ApiException catch (e) {
      if (e.code == 'MOBILE_REQUIRED') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(t('loginRequired')),
              content: Text(t('loginRequiredDesc')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showLoginRequired(context);
                  },
                  child: Text(t('loginBtn')),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = 'Unable to create your order. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// After a pay_now order is created, let the customer choose to
  /// settle it immediately - from wallet balance, or by card
  /// through PayHere.
  Future<void> _choosePaymentMethod(MybaasOrder order) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose Payment Method'),
        content: Text('Total: ${formatMoney(order.total, isInternational: _isInternational)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('wallet'),
            child: const Text('Pay from Wallet'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('card'),
            child: const Text('Pay by Card'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    if (choice == 'wallet') {
      await _payWithWallet(order);
    } else {
      await _payWithCard(order);
    }
  }

  Future<void> _payWithWallet(MybaasOrder order) async {
    final t = context.read<LocaleController>().t;

    try {
      await OrdersService.instance.payOrderWithWallet(order.id);
      if (!mounted) return;
      _showOrderCreatedDialog(t, payNow: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      _showOrderCreatedDialog(t, payNow: true, paymentPending: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pay from wallet. You can retry from My Orders.')),
      );
      _showOrderCreatedDialog(t, payNow: true, paymentPending: true);
    }
  }

  Future<void> _payWithCard(MybaasOrder order) async {
    final t = context.read<LocaleController>().t;

    try {
      final paymentParams = await OrdersService.instance.getPayHerePayment(order.id);
      if (!mounted) return;

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => PayHereWebViewScreen(paymentParams: paymentParams)),
      );

      if (!mounted) return;
      _showOrderCreatedDialog(t, payNow: true, paymentPending: completed != true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start card payment. You can retry from My Orders.')),
      );
      _showOrderCreatedDialog(t, payNow: true, paymentPending: true);
    }
  }

  void _showOrderCreatedDialog(String Function(String) t, {required bool payNow, bool paymentPending = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('orderCreated')),
        content: Text(
          !payNow
              ? 'Your order was created. ${widget.professional.name} will be notified.'
              : paymentPending
                  ? 'Your order was created. Complete payment from My Orders to confirm it.'
                  : 'Your order was created and paid. ${widget.professional.name} will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // close HireScreen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
            child: Text(t('viewMyOrders')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleController>().t;
    final pro = widget.professional;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t('hire'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildProfessionalSummary(pro),
            const SizedBox(height: 24),

            Text(t('location'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: t('locationHint')),
            ),
            const SizedBox(height: 20),

            Text(t('numberOfDays'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildDaysStepper(),
            const SizedBox(height: 20),

            Text(t('preferredDate'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _preferredDate == null
                          ? t('selectDate')
                          : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}',
                      style: TextStyle(
                        color: _preferredDate == null ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(t('paymentMethod'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(t),
            const SizedBox(height: 24),

            _buildTotalCard(t),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canSubmit && !_submitting) ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(t('confirmOrder')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalSummary(Professional pro) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySoft,
            backgroundImage: pro.profilePhoto.isNotEmpty ? NetworkImage(pro.profilePhoto) : null,
            child: pro.profilePhoto.isEmpty
                ? Text(
                    pro.initials,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pro.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(pro.service, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${formatMoney(pro.price, isInternational: _isInternational)}/day',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysStepper() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _days > 1 ? () => setState(() => _days--) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.primary,
          ),
          Text('$_days day${_days == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          IconButton(
            onPressed: () => setState(() => _days++),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(String Function(String) t) {
    return Column(
      children: [
        _paymentOption(
          value: 'pay_now',
          title: t('payNow'),
          subtitle: t('payNowDesc'),
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 10),
        _paymentOption(
          value: 'pay_direct',
          title: t('payDirect'),
          subtitle: t('payDirectDesc'),
          icon: Icons.handshake_outlined,
        ),
      ],
    );
  }

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: selected ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t('total'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryDark)),
          Text(
            formatMoney(_total, isInternational: _isInternational),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
