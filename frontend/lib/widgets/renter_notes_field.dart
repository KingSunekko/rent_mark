import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Optional multi-line "Message to owner" field on the Rental Request
/// form. Local UI state only — no messaging system, just carries a note
/// alongside the request.
class RenterNotesField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const RenterNotesField({
    super.key,
    required this.controller,
    this.label = 'Message to owner',
    this.hint = 'Add a note for the item owner...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 6),
            Text('(optional)', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.primarySofter,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
