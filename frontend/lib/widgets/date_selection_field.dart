import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded, tappable field showing a chosen date (or a placeholder)
/// that opens Flutter's built-in date picker. Used for both Start Date
/// and End Date on the Rental Request form. Local/mock only — no real
/// availability is checked against the picked dates.
class DateSelectionField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String placeholder;
  final String? errorText;
  final VoidCallback onTap;

  const DateSelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = 'Select a date',
    this.errorText,
  });

  static String formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: _hasError ? AppColors.errorSoft : AppColors.primarySofter,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _hasError ? AppColors.error : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: _hasError ? AppColors.error : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value != null ? formatDate(value!) : placeholder,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
