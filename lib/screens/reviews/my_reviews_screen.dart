import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/review_service.dart';
import '../../utils/formatters.dart';

/// Shows only orders this account has actually reviewed - distinct
/// from the Orders screen, which shows every order and prompts for
/// a review on any Completed one that hasn't been reviewed yet.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _loading = true;
  String? _error;
  List<MyReview> _reviews = [];

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
      final list = await ReviewService.instance.myReviews();
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load your reviews. Pull down to try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Reviews')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _reviews.isEmpty && _error == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Column(
                                children: const [
                                  Icon(Icons.star_outline, size: 48, color: AppColors.textMuted),
                                  SizedBox(height: 12),
                                  Text("You haven't reviewed any orders yet.", style: TextStyle(color: AppColors.textMuted)),
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
                          ..._reviews.map(_buildRow),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildRow(MyReview r) {
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
            children: List.generate(5, (i) {
              return Icon(
                i < r.rating ? Icons.star : Icons.star_border,
                size: 16,
                color: AppColors.warning,
              );
            }),
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          Text('${r.orderId} - ${formatShortDate(r.createdAt)}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
