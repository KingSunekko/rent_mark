import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One label/value pair on the Review Rental Request screen — e.g.
/// "ITEM" / "Canon EOS Camera". [emphasize] renders the value larger and
/// in the primary color, used for the estimated total.
class ReviewItem {
  final String label;
  final String value;
  final bool emphasize;

  const ReviewItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
}

/// Stacked label/value review card used on the Rental Request Review
/// screen. Each row shows an uppercase muted label above its value, with
/// a light divider between rows and no divider before an emphasized row
/// (e.g. Estimated Total), so the total stands apart visually.
class RequestReviewSection extends StatelessWidget {
  final List<ReviewItem> items;

  const RequestReviewSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _row(context, items[i]),
            if (i != items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.border),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ReviewItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: item.emphasize
              ? const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                )
              : const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
        ),
      ],
    );
  }
}
