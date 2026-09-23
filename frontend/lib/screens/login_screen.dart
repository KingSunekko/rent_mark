import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../navigation/destination_router.dart';

/// The ONE shared Login screen for all three roles — Renter, Owner, and
/// Admin, owner, and renter accounts authenticate through the same backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isSubmitting = false;

  static final _emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _formError = null;
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email.';
      } else if (!_emailPattern.hasMatch(email)) {
        _emailError = 'Please enter a valid email.';
      } else {
        _emailError = null;
      }

      _passwordError = _passwordController.text.isEmpty
          ? 'Please enter your password.'
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    final authState = context.read<AuthState>();
    try {
      final user = await authState.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destinationForRole(user)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(
                title: 'Welcome Back',
                subtitle: 'Log in to continue using RentMark.',
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomTextField(
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                label: 'Password',
                controller: _passwordController,
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _formError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'LOG IN',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small dev-facing helper so testers can demonstrate the public mock roles
/// without memorizing emails. Purely a Phase 1 convenience — not part of
/// the "real" product UI.
class _MockAccountsHelper extends StatefulWidget {
  final ValueChanged<String> onSelect;

  const _MockAccountsHelper({required this.onSelect});

  @override
  State<_MockAccountsHelper> createState() => _MockAccountsHelperState();
}

class _MockAccountsHelperState extends State<_MockAccountsHelper> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (value) => setState(() => expanded = value),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.science_outlined, color: AppColors.primary),
        title: Text(
          'Demo accounts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: const Text('Renter and Owner test access'),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Choose a role to fill in the local demo login.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MockAccounts.all
                  .where((user) => user.role != UserRole.admin)
                  .map(
                    (u) => _RoleChip(
                      label: u.role.label,
                      onTap: () => widget.onSelect(u.email),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
