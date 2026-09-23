import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import 'item_image.dart';

/// Mid-sized card for the "Featured Items" horizontal rail — smaller than
/// [ItemCard] (Near You), image still the main focus.
class FeaturedItemCard extends StatelessWidget {
  final RentalItem item;
  final VoidCallback onTap;

  const FeaturedItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemImage(
              imageUrl: item.imageUrl,
              icon: item.icon,
              height: 100,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.priceLabelCompact,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 1),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
