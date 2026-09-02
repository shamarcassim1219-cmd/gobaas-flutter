import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/professional.dart';
import '../../utils/formatters.dart';
import '../hire/hire_screen.dart';

/// Full profile view for a Baas found in search results - built
/// entirely from the same Professional object the search results
/// already carry (no extra API call needed), with a Hire button at
/// the bottom that goes straight into the same HireScreen flow.
class BaasProfileScreen extends StatelessWidget {
  final Professional professional;
  final bool isInternational;

  const BaasProfileScreen({super.key, required this.professional, required this.isInternational});

  @override
  Widget build(BuildContext context) {
    final pro = professional;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(pro.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      pro.initials,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pro.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      if (pro.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.info, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: pro.isOnline ? AppColors.success : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        pro.isOnline ? 'Online now' : 'Offline',
                        style: TextStyle(fontSize: 12.5, color: pro.isOnline ? AppColors.success : AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _statBox(Icons.star, pro.rating != null ? pro.rating!.toStringAsFixed(1) : '-', '${pro.reviews} reviews')),
                const SizedBox(width: 10),
                Expanded(child: _statBox(Icons.task_alt, '${pro.completedOrders}', 'jobs done')),
                const SizedBox(width: 10),
                Expanded(child: _statBox(Icons.payments_outlined, formatMoney(pro.price, isInternational: isInternational), 'per day')),
              ],
            ),
            const SizedBox(height: 24),

            if (pro.about.isNotEmpty) ...[
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(pro.about, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
            ],

            Text('Services', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pro.services.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            if (pro.location.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(pro.location, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  if (pro.distanceKm != null) ...[
                    const SizedBox(width: 6),
                    Text('· ${pro.distanceKm!.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (pro.reviewList.isNotEmpty) ...[
              Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...pro.reviewList.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                          children: [
                            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const Spacer(),
                            ...List.generate(5, (i) => Icon(i < r.rating ? Icons.star : Icons.star_border, size: 13, color: AppColors.warning)),
                          ],
                        ),
                        if (r.comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r.comment, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => HireScreen(professional: pro)),
                  );
                },
                child: const Text('Hire This Baas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
