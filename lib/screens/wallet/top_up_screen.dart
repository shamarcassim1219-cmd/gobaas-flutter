import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_service.dart';
import '../../services/api_exception.dart';
import 'payhere_webview_screen.dart';

/// Amount entry for a wallet top-up - creates the PENDING
/// transaction server-side, then hands the returned PayHere
/// Checkout fields to PayHereWebViewScreen to actually collect
/// payment. Pops back with `true` if the payment completed, so
/// WalletScreen/CustomerHomeScreen know to refresh the balance.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const List<double> _quickAmounts = [500, 1000, 2500, 5000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  bool get _canSubmit {
    final amount = _amount;
    return amount != null && amount > 0;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final paymentParams = await WalletService.instance.createPayHereTopUp(_amount!);

      if (!mounted) return;

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PayHereWebViewScreen(paymentParams: paymentParams),
        ),
      );

      if (!mounted) return;

      if (completed == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _submitting = false);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to start payment. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Top Up')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Amount (LKR)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '0.00', prefixText: 'Rs. '),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                return OutlinedButton(
                  onPressed: () {
                    _amountController.text = amount.toStringAsFixed(0);
                    setState(() {});
                  },
                  child: Text('Rs. ${amount.toStringAsFixed(0)}'),
                );
              }).toList(),
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
                    : const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
