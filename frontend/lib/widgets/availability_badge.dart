import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';

/// Small pill badge showing an item's availability — a subtle dot plus
/// label. Shared by every card type so the indicator looks identical
/// everywhere it appears.
class AvailabilityBadge extends StatelessWidget {
  final AvailabilityStatus status;
  final bool onImage;

  const AvailabilityBadge({
    super.key,
    required this.status,
    this.onImage = false,
  });

  Color get _dotColor {
    switch (status) {
      case AvailabilityStatus.available:
      case AvailabilityStatus.availableToday:
        return AppColors.success;
      case AvailabilityStatus.unavailable:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.white.withValues(alpha: 0.94)
            : AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: _dotColor),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
