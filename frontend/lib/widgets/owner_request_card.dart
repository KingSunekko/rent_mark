import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import 'item_image.dart';
import 'request_status_badge.dart';

/// Full-width card for the Owner's "Rental Requests" list — item photo
/// on top, then item name, who requested it, rental period, duration,
/// estimated total, and a status badge. Mirrors the Renter side's
/// `RentalRequestCard` layout so both roles feel consistent; the one
/// addition here is "Requested by renter", since the Owner needs to
/// know who's asking.
class OwnerRequestCard extends StatelessWidget {
  final RentalRequest request;
  final VoidCallback? onTap;

  const OwnerRequestCard({super.key, required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemImage(
              imageUrl: request.item.imageUrl,
              icon: request.item.icon,
              height: 140,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Requested by',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.renterName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    request.rentalPeriodLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.durationLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        request.estimatedTotalLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      RequestStatusBadge(status: request.status),
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
