import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_service.dart';
import '../../utils/formatters.dart';

/// A focused history of just top-ups and withdrawals - the full
/// wallet ledger (WalletScreen) also includes other entry types
/// (referral bonuses, order holds/releases), so this filters down
/// to only TOPUP and WITHDRAWAL for a cleaner "money in/out of my
/// bank" view from Settings.
class TopUpWithdrawHistoryScreen extends StatefulWidget {
  const TopUpWithdrawHistoryScreen({super.key});

  @override
  State<TopUpWithdrawHistoryScreen> createState() => _TopUpWithdrawHistoryScreenState();
}

class _TopUpWithdrawHistoryScreenState extends State<TopUpWithdrawHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<LedgerEntry> _entries = [];
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
      final (_, ledger) = await WalletService.instance.load();
      final filtered = ledger.where((e) => e.type == 'TOPUP' || e.type == 'WITHDRAWAL').toList();

      if (!mounted) return;
      setState(() {
        _entries = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your history. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Top Up / Withdraw History')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _entries.isEmpty && _error == null
                    ? _buildEmptyState()
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            ),
                          ..._entries.map(_buildEntryRow),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                const Text('No top-ups or withdrawals yet.', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryRow(LedgerEntry entry) {
    final isTopUp = entry.type == 'TOPUP';
    final isPending = entry.state == 'pending' || entry.state == 'withdrawing';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopUp ? AppColors.successSoft : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Icon(
              isTopUp ? Icons.add : Icons.arrow_outward,
              size: 18,
              color: isTopUp ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTopUp ? 'Top Up' : 'Withdrawal',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (entry.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(entry.note, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
                const SizedBox(height: 3),
                Text(formatShortDate(entry.createdAt), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                if (isPending) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      entry.state == 'withdrawing' ? 'PROCESSING' : 'PENDING',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.warning),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${entry.amount < 0 ? '-' : '+'}${formatMoney(entry.amount.abs(), isInternational: _isInternational)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: isTopUp ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
