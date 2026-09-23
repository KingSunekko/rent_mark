import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RentalStepIndicator extends StatelessWidget {
  final int currentStep;
  const RentalStepIndicator({super.key, required this.currentStep});

  static const labels = ['Dates', 'Details', 'Review', 'Submitted'];

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(labels.length, (index) {
      final active = index <= currentStep;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 5,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (index < labels.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ),
      );
    }),
  );
}
