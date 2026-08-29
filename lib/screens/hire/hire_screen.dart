import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/orders_service.dart';
import '../../services/api_client.dart';
import '../../services/api_exception.dart';
import '../../models/professional.dart';
import '../../utils/formatters.dart';
import '../orders/orders_screen.dart';

/// Mirrors the web apps' hire form - shown after tapping a search
/// result. Location, number of days, a preferred date, and payment
/// method (pay now vs pay the Baas directly), with the total
/// recalculated live as days changes. Submits via
/// OrdersService.createOrder, same as the web apps' hire button.
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
  String _paymentMethod = 'pay_now'; // 'pay_now' | 'pay_direct'

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

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await OrdersService.instance.createOrder(
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

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Created'),
          content: Text(
            _paymentMethod == 'pay_now'
                ? 'Your order was created. Complete payment from My Orders to confirm it.'
                : 'Your order was created. ${widget.professional.name} will be notified.',
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
              child: const Text('View My Orders'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.code == 'MOBILE_REQUIRED'
            ? 'Please verify a mobile number before hiring - go to Profile to add one.'
            : e.message;
      });
    } catch (e) {
      setState(() => _error = 'Unable to create your order. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pro = widget.professional;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hire')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildProfessionalSummary(pro),
            const SizedBox(height: 24),

            Text('Location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Where should the Baas come?'),
            ),
            const SizedBox(height: 20),

            Text('Number of Days', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildDaysStepper(),
            const SizedBox(height: 20),

            Text('Preferred Date', style: Theme.of(context).textTheme.titleMedium),
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
                          ? 'Select a date'
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

            Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),

            _buildTotalCard(),

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
                    : const Text('Confirm Order'),
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

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _paymentOption(
          value: 'pay_now',
          title: 'Pay Now',
          subtitle: 'Pay online, held securely until the job is done',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 10),
        _paymentOption(
          value: 'pay_direct',
          title: 'Pay Direct',
          subtitle: 'Pay the Baas directly, in person',
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

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryDark)),
          Text(
            formatMoney(_total, isInternational: _isInternational),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
