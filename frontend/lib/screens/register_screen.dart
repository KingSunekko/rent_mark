import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../state/auth_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

/// Registration screen for the public sign-up flow. Only Renter and Owner
/// roles are chosen afterward on Role Selection — Admin is never offered
/// here; admin accounts are assumed managed separately (see spec §7).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _communityController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _profileImageBytes;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _communityError;
  bool _isSubmitting = false;

  static final _emailPattern = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  Future<void> _pickProfilePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _profileImageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select that photo.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter your full name.'
          : null;

      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email.';
      } else if (!_emailPattern.hasMatch(email)) {
        _emailError = 'Please enter a valid email.';
      } else if (context.read<AuthState>().findByEmail(email) != null) {
        _emailError = 'An account with this email already exists.';
      } else {
        _emailError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Please enter a password.';
      } else if (_passwordController.text.length < 8) {
        _passwordError = 'Password must contain at least 8 characters.';
      } else {
        _passwordError = null;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = 'Please confirm your password.';
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match.';
      } else {
        _confirmPasswordError = null;
      }

      _communityError = _communityController.text.trim().isEmpty
          ? 'Please enter your community or location.'
          : null;
    });

    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _communityError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    context.read<AuthState>().startRegistration(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      community: _communityController.text.trim(),
      profileImageBytes: _profileImageBytes,
      password: _passwordController.text,
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
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
                title: 'Create your RentMark account',
                subtitle: 'Join your community and start renting.',
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primarySofter,
                          backgroundImage: _profileImageBytes == null
                              ? null
                              : MemoryImage(_profileImageBytes!),
                          child: _profileImageBytes == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 42,
                                  color: AppColors.textMuted,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: _pickProfilePhoto,
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Choose profile photo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _pickProfilePhoto,
                      child: Text(
                        _profileImageBytes == null
                            ? 'ADD PROFILE PHOTO'
                            : 'CHANGE PROFILE PHOTO',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Full Name',
                hint: 'Juan Dela Cruz',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                errorText: _nameError,
              ),
              const SizedBox(height: AppSpacing.md),
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
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                controller: _confirmPasswordController,
                errorText: _confirmPasswordError,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                label: 'Community / Location',
                hint: 'e.g. Davao Community',
                icon: Icons.place_outlined,
                controller: _communityController,
                errorText: _communityError,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'CREATE ACCOUNT',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Log In',
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
