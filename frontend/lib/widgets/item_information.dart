import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Item Information" — a light, unobtrusive key/value grid for
/// Condition, Category, Availability, and Rental Type. Deliberately not
/// a heavy card per spec (§17: "not every section a separate heavy
/// card") — a soft tinted container with internal dividers instead.
class ItemInformation extends StatelessWidget {
  final String condition;
  final String category;
  final String availabilityLabel;
  final String rentalType;

  const ItemInformation({
    super.key,
    required this.condition,
    required this.category,
    required this.availabilityLabel,
    required this.rentalType,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Condition', condition),
      ('Category', category),
      ('Availability', availabilityLabel),
      ('Rental Type', rentalType),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Information', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySofter,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rows[i].$1,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        rows[i].$2,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != rows.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
