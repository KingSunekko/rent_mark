import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/role_selection_card.dart';
import '../widgets/primary_button.dart';
import '../navigation/destination_router.dart';

/// Shown right after Registration. Only Renter and Owner are offered —
/// Admin is intentionally never shown on this screen (spec §7, §10).
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _continue() async {
    if (_selected == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final user = await context.read<AuthState>().completeRegistration(
        _selected!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destinationForRole(user)),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
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
                title: 'How will you use RentMark?',
                subtitle: 'Choose how you want to use the platform.',
              ),
              const SizedBox(height: AppSpacing.xl),
              RoleSelectionCard(
                icon: Icons.search_rounded,
                title: 'Renter',
                description: 'Find and rent items from your community.',
                selected: _selected == UserRole.renter,
                onTap: () => setState(() => _selected = UserRole.renter),
              ),
              const SizedBox(height: AppSpacing.md),
              RoleSelectionCard(
                icon: Icons.storefront_rounded,
                title: 'Owner',
                description: 'List your items and rent out things you own.',
                selected: _selected == UserRole.owner,
                onTap: () => setState(() => _selected = UserRole.owner),
              ),
              const Spacer(),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              PrimaryButton(
                label: 'CONTINUE',
                isLoading: _submitting,
                onPressed: _selected == null || _submitting ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
