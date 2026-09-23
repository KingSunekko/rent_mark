import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';

/// A single category chip — blue-filled when selected, light/muted when
/// not. Used in the horizontally scrollable category row on Home and
/// Search, and inside the filter sheet.
class CategoryChip extends StatelessWidget {
  final ItemCategory category;
  final bool selected;
  final VoidCallback onTap;
  final bool showIcon;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.primarySofter,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                category.icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
