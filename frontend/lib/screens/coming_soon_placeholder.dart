import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Simple "coming later" placeholder reused for the Rentals, Notifications
/// and Profile bottom-nav tabs, and for the Item Details stub reached by
/// tapping an item card. No real screens built here yet (Phase 3+).
class ComingSoonPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showBack;
  final bool showAppBar;
  final String message;

  const ComingSoonPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    this.showBack = false,
    this.showAppBar = false,
    this.message = 'Coming in a later phase',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              title: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Icon(icon, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
