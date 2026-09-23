import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/rentmark_brand_artwork.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// The main authentication entry point — reached right after Splash.
/// Leads to Login or Register; the primary CTA (Create Account) is
/// visually dominant per spec.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'RentMark',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const RentMarkBrandArtwork(height: 230),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Find what you need.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Borrow nearby. Earn from what you own.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              const Row(
                children: [
                  Expanded(
                    child: _Benefit(
                      icon: Icons.search_rounded,
                      title: 'For renters',
                      message: 'Find useful items close to home.',
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Benefit(
                      icon: Icons.payments_outlined,
                      title: 'For owners',
                      message: 'Put idle items to work.',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'LOG IN',
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'CREATE ACCOUNT',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
