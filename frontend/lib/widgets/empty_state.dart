import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

/// Shown when a search or filter combination returns nothing — or, with
/// a custom [icon]/[title]/[message]/[actionLabel], for any other empty
/// list (e.g. My Rentals with no requests yet).
///
/// Two named flavors ship built in: the default (search/filter turned up
/// nothing — "CLEAR SEARCH") and [EmptyState.noCategoryItems] (a
/// category has no items — "VIEW ALL ITEMS").
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.title = 'No items found',
    this.message = 'Try searching for another item or category.',
    this.actionLabel = 'CLEAR SEARCH',
    this.icon = Icons.search_off_rounded,
    this.onAction,
  });

  const EmptyState.noCategoryItems({super.key, required this.onAction})
    : title = 'No items available',
      message = 'Try another category.',
      actionLabel = 'VIEW ALL ITEMS',
      icon = Icons.search_off_rounded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primarySofter,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(icon, size: 38, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 180,
              child: PrimaryButton(label: actionLabel, onPressed: onAction!),
            ),
          ],
        ],
      ),
    );
  }
}
