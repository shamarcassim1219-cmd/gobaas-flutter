import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/professional.dart';
import '../utils/formatters.dart';

/// One search-result row - mirrors the web app's professional card:
/// avatar/initials, name with a verified badge, rating, distance or
/// location text, and the daily rate. Shows an "Offline" tag when
/// this card is part of the backend's offline-fallback list (no
/// online Baas were found nearby, so it showed everyone matching
/// instead of a blank screen) - see CustomerHomeScreen's
/// usedOfflineFallback banner for the list-level version of this
/// same note.
class ProfessionalCard extends StatelessWidget {
  final Professional professional;
  final bool isInternational;
  final VoidCallback onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    required this.isInternational,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          professional.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (professional.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 15, color: AppColors.info),
                      ],
                      if (!professional.isOnline) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: const Text(
                            'Offline',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    professional.service,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (professional.rating != null) ...[
                        const Icon(Icons.star, size: 13, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          professional.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          professional.distanceKm != null
                              ? '${professional.distanceKm!.toStringAsFixed(1)} km away'
                              : professional.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatMoney(professional.price, isInternational: isInternational),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (professional.profilePhoto.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primarySoft,
        backgroundImage: NetworkImage(professional.profilePhoto),
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primarySoft,
      child: Text(
        professional.initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
