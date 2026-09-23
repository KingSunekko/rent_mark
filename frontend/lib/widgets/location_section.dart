import 'package:flutter/material.dart';

import '../models/rental_item.dart';
import '../services/maps_service.dart';
import '../theme/app_theme.dart';

class LocationSection extends StatelessWidget {
  final RentalItem item;
  const LocationSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Location & pickup', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySofter,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.locationLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('General area · Distance not calculated'),
            const SizedBox(height: 16),
            Text(
              'Public meeting point',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              item.meetingPoint.trim().isEmpty
                  ? 'No public meeting point provided yet.'
                  : item.meetingPoint,
            ),
            if (item.pickupInstructions.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pickup instructions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(item.pickupInstructions),
            ],
            if (item.mapSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Google Maps'),
                onPressed: () async {
                  final opened = await MapsService.openMeetingPoint(
                    item.mapSearchQuery,
                  );
                  if (!context.mounted || opened) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open Maps. Search for the meeting point in your browser.',
                      ),
                    ),
                  );
                },
              ),
              const Text(
                'Opens an external map search. Confirm the landmark with the owner before travelling.',
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
