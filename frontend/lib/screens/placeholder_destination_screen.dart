import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../widgets/primary_button.dart';
import 'welcome_screen.dart';

/// A single, simple placeholder screen reused for Home, Owner Dashboard,
/// and Admin Dashboard. It exists ONLY to demonstrate role-based
/// navigation — the real destinations are built in later phases.
class PlaceholderDestinationScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final MockUser user;

  const PlaceholderDestinationScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.user,
  });

  factory PlaceholderDestinationScreen.forRole(MockUser user) {
    switch (user.role) {
      case UserRole.renter:
        return PlaceholderDestinationScreen(
          title: 'Home',
          message: 'Phase 2 — Coming Soon',
          icon: Icons.home_rounded,
          user: user,
        );
      case UserRole.owner:
        return PlaceholderDestinationScreen(
          title: 'Owner Dashboard',
          message: 'Coming in a later phase',
          icon: Icons.dashboard_rounded,
          user: user,
        );
      case UserRole.admin:
        return PlaceholderDestinationScreen(
          title: 'Admin Dashboard',
          message: 'Coming in a later phase',
          icon: Icons.admin_panel_settings_rounded,
          user: user,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(icon, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Signed in as ${user.name} · ${user.role.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'LOG OUT',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
