import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';

/// Static informational screen - no backend calls needed. App
/// description, version, and a quick link to the website, matching
/// the "About" section the web apps show in their footer/menu.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About GOBAAS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: BrandLogo(fontSize: 32, animate: false)),
            const SizedBox(height: 24),
            const Text(
              'GOBAAS connects you with trusted, verified professionals '
              '("Baas") near you - for home repairs, construction work, '
              'and skilled trade services across Sri Lanka.',
              style: TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _infoRow('Version', '1.0.0'),
            _infoRow('Website', 'findbass.store'),
            const SizedBox(height: 32),
            const Text(
              'Every Baas on GOBAAS goes through an identity verification '
              'process before they can accept work, so you can hire with '
              'confidence.',
              style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
