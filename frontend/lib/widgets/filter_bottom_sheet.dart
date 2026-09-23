import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import '../widgets/primary_button.dart';
import '../widgets/category_chip.dart';

enum AvailabilityFilter { available, all }

enum SortOption { nearest, lowestPrice, highestPrice, highestRated }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.nearest:
        return 'Recommended';
      case SortOption.lowestPrice:
        return 'Lowest Price';
      case SortOption.highestPrice:
        return 'Highest Price';
      case SortOption.highestRated:
        return 'Highest Rated';
    }
  }
}

/// Result bundle returned when the filter sheet is applied.
class FilterResult {
  final ItemCategory category;
  final AvailabilityFilter availability;
  final SortOption sort;

  const FilterResult({
    required this.category,
    required this.availability,
    required this.sort,
  });
}

/// A simple, single-purpose filter sheet — category, availability, sort.
/// Deliberately not a full marketplace filter system per spec.
Future<FilterResult?> showFilterSheet(
  BuildContext context, {
  required FilterResult current,
}) {
  return showModalBottomSheet<FilterResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  final FilterResult initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ItemCategory _category = widget.initial.category;
  late AvailabilityFilter _availability = widget.initial.availability;
  late SortOption _sort = widget.initial.sort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySofter,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('CATEGORY', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.values.map((c) {
                return CategoryChip(
                  category: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'AVAILABILITY',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: AvailabilityFilter.values.map((a) {
                final selected = _availability == a;
                final label = a == AvailabilityFilter.available
                    ? 'Available'
                    : 'All';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _availability = a),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.primarySofter,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('SORT BY', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SortOption.values.map((s) {
                final selected = _sort == s;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _sort = s),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primarySofter,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'APPLY FILTERS',
              onPressed: () => Navigator.of(context).pop(
                FilterResult(
                  category: _category,
                  availability: _availability,
                  sort: _sort,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
