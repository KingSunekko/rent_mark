import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows the calculated rental duration once both dates are picked —
/// "Rental Duration / 3 days". In Phase 4A, [days] stays null and shows
/// a "-- days" placeholder; Phase 4B wires in the real calculation.
class RentalDurationDisplay extends StatelessWidget {
  final int? days;

  const RentalDurationDisplay({super.key, this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Rental Duration',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Text(
            days != null ? '$days ${days == 1 ? 'day' : 'days'}' : '-- days',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
