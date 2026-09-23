import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_pricing.dart';

/// Rental Price / Duration / Estimated Total summary block.
///
/// Phase 4A only ever renders the placeholder state ([durationDays] and
/// [estimatedTotal] left null) — real calculation from the picked dates
/// arrives in Phase 4B, which will simply start passing real numbers
/// into this same widget instead of nulls.
class RentalCostSummary extends StatelessWidget {
  final String pricePerDayLabel;
  final int? durationDays;
  final num? estimatedTotal;
  final int discountPercent;
  final String? originalPriceLabel;

  const RentalCostSummary({
    super.key,
    required this.pricePerDayLabel,
    this.durationDays,
    this.estimatedTotal,
    this.discountPercent = 0,
    this.originalPriceLabel,
  });

  String get _durationText => durationDays != null
      ? '$durationDays ${durationDays == 1 ? 'day' : 'days'}'
      : '-- days';

  String get _totalText =>
      estimatedTotal != null ? formatPesos(estimatedTotal!) : '₱----';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estimated Cost', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySofter,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _row(context, 'Rental Price', pricePerDayLabel),
              if (discountPercent > 0) ...[
                const SizedBox(height: 10),
                _row(context, 'Regular rate', originalPriceLabel ?? ''),
                const SizedBox(height: 10),
                _row(context, 'Owner discount', '$discountPercent% every day'),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _row(context, 'Duration', _durationText),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _row(context, 'Estimated Total', _totalText, emphasize: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 14.5 : 13.5,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 19 : 14,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
            letterSpacing: emphasize ? -0.3 : 0,
          ),
        ),
      ],
    );
  }
}
