import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared rounded input field used by Login and Register.
///
/// Supports a leading icon, a clear label above the field, a focus state
/// (blue border) and an error state (red border + inline message).
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.focusNode,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
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
            fillColor: _hasError
                ? AppColors.errorSoft
                : AppColors.primarySofter,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: _hasError ? AppColors.error : AppColors.textMuted,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : Colors.transparent,
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: _hasError ? AppColors.error : AppColors.primary,
                width: 1.6,
              ),
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
