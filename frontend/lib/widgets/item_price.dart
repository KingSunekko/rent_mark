import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import 'availability_badge.dart';

/// Rental price paired with the availability badge, right under
/// [ItemHeader] on Item Details — the two most-scanned facts on the
/// screen after the image and name.
class ItemPrice extends StatelessWidget {
  final String priceLabel;
  final AvailabilityStatus availability;
  final String? originalPriceLabel;
  final int discountPercent;

  const ItemPrice({
    super.key,
    required this.priceLabel,
    required this.availability,
    this.originalPriceLabel,
    this.discountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (discountPercent > 0) ...[
                Text(
                  originalPriceLabel ?? '',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$discountPercent% off · Owner offer',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              Text(
                priceLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AvailabilityBadge(status: availability),
      ],
    );
  }
}
