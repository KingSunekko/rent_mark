import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _community;
  late final TextEditingController _phone;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().currentUser!;
    _name = TextEditingController(text: user.name);
    _community = TextEditingController(text: user.community);
    _phone = TextEditingController(text: user.phone);
    _bio = TextEditingController(text: user.bio);
  }
  
  @override
  void dispose() {
    _name.dispose();
    _community.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthState>().updateProfile(
      name: _name.text,
      community: _community.text,
      phone: _phone.text,
      bio: _bio.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Edit Profile')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _community,
              decoration: const InputDecoration(
                labelText: 'Community / Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Community is required.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bio,
              minLines: 3,
              maxLines: 5,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell your community a little about yourself.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SAVE PROFILE'),
            ),
          ],
        ),
      ),
    ),
  );
}
