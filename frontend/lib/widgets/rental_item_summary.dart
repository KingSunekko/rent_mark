import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import 'item_image.dart';

/// Compact reminder of the item being requested — image, name, price,
/// rating. Sits at the top of the Rental Request form; reused wherever
/// the request flow needs to remind the renter what they're requesting.
class RentalItemSummary extends StatelessWidget {
  final RentalItem item;

  const RentalItemSummary({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
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
            width: 64,
            height: 64,
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
                  item.category.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item.priceLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
