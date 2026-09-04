import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/complaint_service.dart';
import '../../utils/formatters.dart';
import '../order_detail/order_detail_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  bool _loading = true;
  String? _error;
  List<Complaint> _complaints = [];

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
      final list = await ComplaintService.instance.myComplaints();
      if (!mounted) return;
      setState(() {
        _complaints = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your complaints. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Complaints')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _complaints.isEmpty && _error == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Column(
                                children: const [
                                  Icon(Icons.flag_outlined, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text('No complaints filed.', style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                            ),
                          ..._complaints.map(_buildRow),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildRow(Complaint c) {
    final (color, bg) = switch (c.status) {
      'Approved' => (AppColors.success, AppColors.successSoft),
      'Rejected' => (AppColors.danger, AppColors.dangerSoft),
      _ => (AppColors.warning, AppColors.warningSoft),
    };

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: c.orderId)),
        );
      },
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
                Expanded(child: Text(c.reason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  child: Text(c.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.orderId, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(c.details, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            if (c.adminNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${c.adminNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
            ],
            if (c.refunded && c.refundAmount != null) ...[
              const SizedBox(height: 6),
              Text(
                'Refunded: ${formatMoney(c.refundAmount!, isInternational: false)}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatShortDate(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
