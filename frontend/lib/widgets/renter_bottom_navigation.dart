import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Renter bottom navigation bar — Home, Search, Rentals, Alerts,
/// Profile. Selected tab uses the blue accent; unselected tabs stay
/// muted gray. Purely presentational — [RenterShell] owns tab state.
class RenterBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const RenterBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.search_rounded, Icons.search_rounded, 'Search'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Rentals'),
    (Icons.notifications_rounded, Icons.notifications_none_rounded, 'Alerts'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = selectedIndex == i;
            final (selectedIcon, unselectedIcon, label) = _items[i];
            return InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      child: Icon(
                        selected ? selectedIcon : unselectedIcon,
                        size: 23,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
