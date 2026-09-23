import 'package:flutter/material.dart';

import '../models/rental_request.dart';
import '../theme/app_theme.dart';

/// Rental progress tracker including the Phase 8 return flow.
class RentalStatusTimeline extends StatelessWidget {
  final RentalRequest request;

  const RentalStatusTimeline({super.key, required this.request});

  int get _currentStep {
    switch (request.status) {
      case RentalRequestStatus.pending:
        return 0;
      case RentalRequestStatus.approved:
        return 1;
      case RentalRequestStatus.active:
        return 2;
      case RentalRequestStatus.returnRequested:
        return 3;
      case RentalRequestStatus.completed:
        return 4;
      case RentalRequestStatus.rejected:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (request.status == RentalRequestStatus.rejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This request was rejected, so rental tracking did not start.',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    const labels = [
      'Request sent',
      'Approved',
      'Active rental',
      'Return requested',
      'Return confirmed',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rental Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < labels.length; i++)
            _TimelineRow(
              label: labels[i],
              isComplete: i <= _currentStep,
              showLine: i != labels.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool isComplete;
  final bool showLine;

  const _TimelineRow({
    required this.label,
    required this.isComplete,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete ? AppColors.primary : AppColors.border,
                  ),
                  child: isComplete
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isComplete
                          ? AppColors.primarySoft
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isComplete ? FontWeight.w700 : FontWeight.w500,
                  color: isComplete
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
