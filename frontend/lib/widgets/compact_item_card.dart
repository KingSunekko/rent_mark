import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import 'item_image.dart';

/// Compact horizontal list row — used for "Popular in Your Community" and
/// for Search results, where a dense list reads better than large cards.
class CompactItemCard extends StatelessWidget {
  final RentalItem item;
  final VoidCallback onTap;

  const CompactItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ItemImage(
              imageUrl: item.imageUrl,
              icon: item.icon,
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        item.category.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 6),
                      Text('·', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
