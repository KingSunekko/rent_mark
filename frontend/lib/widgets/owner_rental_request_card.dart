import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import 'item_image.dart';
import 'request_status_badge.dart';

/// Reusable card for an incoming rental request on the Owner side —
/// item photo on top, then name, "Requested by renter", rental
/// period, duration, estimated total, and a status badge.
///
/// Mirrors the Renter side's `RentalRequestCard` (same `ItemImage`
/// fallback behavior, same `RequestStatusBadge`), with the renter's
/// name folded into a single line so the Owner can scan who's asking
/// without extra vertical space. Purely presentational — no approve/
/// reject actions and no tap-through to a details screen live here.
class OwnerRentalRequestCard extends StatelessWidget {
  final RentalRequest request;
  final VoidCallback? onTap;

  const OwnerRentalRequestCard({super.key, required this.request, this.onTap});

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
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'Requested by '),
                        TextSpan(
                          text: request.renterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
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
                          fontSize: 18,
                          letterSpacing: -0.2,
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
