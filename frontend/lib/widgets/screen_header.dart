import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared header used at the top of Login, Register, Role Selection and
/// Forgot Password — an optional back button, a bold title, and muted
/// supporting text underneath.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _BackButton(),
          ),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySofter,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
