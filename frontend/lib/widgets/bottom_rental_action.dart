import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sticky bottom action bar on Item Details — price on the left, a
/// "REQUEST TO RENT" button on the right. The button is a Phase 3
/// placeholder only: tapping it shows a message that rental requests
/// arrive in Phase 4, nothing is submitted or booked.
class BottomRentalAction extends StatelessWidget {
  final String priceLabel;
  final VoidCallback onRequestTap;
  final bool enabled;
  final String? disabledReason;

  const BottomRentalAction({
    super.key,
    required this.priceLabel,
    required this.onRequestTap,
    this.enabled = true,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm + 2,
          AppSpacing.lg,
          AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF161E33).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  'per day',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: enabled ? onRequestTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    enabled
                        ? 'REQUEST TO RENT'
                        : disabledReason ?? 'UNAVAILABLE',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
