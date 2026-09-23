import 'package:flutter/material.dart';

import '../models/rental_review.dart';
import '../theme/app_theme.dart';

class ReviewCard extends StatelessWidget {
  final RentalReview review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Text(
                review.renterName.isEmpty
                    ? '?'
                    : review.renterName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.renterName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    review.itemName,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF5A623),
                ),
                const SizedBox(width: 3),
                Text(
                  '${review.rating}/5',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(review.comment),
        ],
      ],
    ),
  );
}
