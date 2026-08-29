import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import 'login_screen.dart';

class LanguageOption {
  final String code;
  final String label;
  final String native;
  const LanguageOption(this.code, this.label, this.native);
}

const _languages = [
  LanguageOption('en', 'English', 'English'),
  LanguageOption('si', 'Sinhala', 'සිංහල'),
  LanguageOption('ta', 'Tamil', 'தமிழ்'),
];

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;

  Future<void> _continue() async {
    if (_selected == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mybaas_lang', _selected!);

    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.medium,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: AppMotion.curve)),
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const BrandLogo(fontSize: 32),
              const SizedBox(height: 8),
              Text(
                'Select your language',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.xl),
              ..._languages.asMap().entries.map((entry) {
                final index = entry.key;
                final lang = entry.value;
                final isSelected = _selected == lang.code;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _LanguageCard(
                    lang: lang,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selected = lang.code),
                  ),
                ).animate().fadeIn(
                      delay: (300 + index * 90).ms,
                      duration: AppMotion.medium,
                    ).slideX(
                      begin: 0.08,
                      end: 0,
                      delay: (300 + index * 90).ms,
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                    );
              }),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _continue,
                  child: const Text('Continue'),
                ),
              ).animate().fadeIn(delay: 650.ms, duration: AppMotion.medium),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageOption lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.native, style: Theme.of(context).textTheme.titleLarge),
                  if (lang.native != lang.label)
                    Text(lang.label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1 : 0,
              duration: AppMotion.fast,
              curve: AppMotion.bouncy,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent,
                child: Icon(Icons.check, size: 16, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
