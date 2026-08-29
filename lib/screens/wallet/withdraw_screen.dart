import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_service.dart';
import '../../services/api_exception.dart';
import '../../utils/formatters.dart';

/// Request a withdrawal from the available wallet balance - amount
/// and where to send it (bank/mobile-money details as free text for
/// now). Mirrors the admin side's withdrawal queue: this creates the
/// request, an admin approves/pays it out separately.
class WithdrawScreen extends StatefulWidget {
  final double availableBalance;
  final bool isInternational;

  const WithdrawScreen({
    super.key,
    required this.availableBalance,
    required this.isInternational,
  });

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  bool get _canSubmit {
    final amount = _amount;
    return amount != null &&
        amount > 0 &&
        amount <= widget.availableBalance &&
        _accountController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await WalletService.instance.requestWithdrawal(
        amount: _amount!,
        accountDetails: _accountController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Withdrawal Requested'),
          content: const Text('Your withdrawal request has been submitted and is pending approval.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(true); // close WithdrawScreen, signal refresh
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unable to submit your withdrawal request. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Withdraw')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available to withdraw', style: TextStyle(fontSize: 13, color: AppColors.primaryDark)),
                  Text(
                    formatMoney(widget.availableBalance, isInternational: widget.isInternational),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Amount', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            const SizedBox(height: 20),

            Text('Account Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Bank account or mobile money number to send the withdrawal to.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accountController,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'e.g. Bank name, account number, name on account'),
            ),

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
                    : const Text('Request Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
