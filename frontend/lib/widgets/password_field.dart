import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'custom_text_field.dart';

/// A password input with an eye icon toggling hidden/visible text.
/// Reused for both Password and Confirm Password fields.
class PasswordField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = 'Enter your password',
    this.errorText,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint,
      icon: Icons.lock_outline_rounded,
      controller: widget.controller,
      errorText: widget.errorText,
      obscureText: _obscure,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
