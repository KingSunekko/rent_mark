import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Prominent rounded search field with a leading search icon and a
/// trailing filter button. Reused on Home (read-only, routes to Search)
/// and on the Search screen itself (live, editable).
class RentMarkSearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  const RentMarkSearchBar({
    super.key,
    this.hint = 'Search items...',
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.onFilterTap,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySofter,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              focusNode: focusNode,
              autofocus: autofocus,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
