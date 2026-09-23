import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/owner_listings_store.dart';
import '../models/rental_request.dart';
import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../state/favorites_state.dart';
import '../state/rental_requests_state.dart';
import '../state/reviews_state.dart';
import '../theme/app_theme.dart';
import '../widgets/review_card.dart';
import 'edit_profile_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'owner_listings_screen.dart';
import 'welcome_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String name;
  final String community;
  final UserRole role;
  final String? email;
  final bool isCurrentUser;
  final String? userId;

  const UserProfileScreen({
    super.key,
    required this.name,
    required this.community,
    required this.role,
    this.email,
    this.isCurrentUser = false,
    this.userId,
  });

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (context.mounted) context.read<AuthState>().updateProfileImage(bytes);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to select that photo.')),
        );
      }
    }
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    final displayName = isCurrentUser ? user?.name ?? name : name;
    final displayCommunity = isCurrentUser
        ? user?.community ?? community
        : community;
    final displayEmail = isCurrentUser ? user?.email ?? email : null;
    final photo = isCurrentUser ? user?.profileImageBytes : null;
    final phone = isCurrentUser ? user?.phone ?? '' : '';
    final bio = isCurrentUser ? user?.bio ?? '' : '';

    final allRequests = context.watch<RentalRequestsState>().requests;
    final requests = allRequests.where((request) {
      return role == UserRole.owner
          ? (isCurrentUser || request.item.ownerName == displayName)
          : request.renterName == displayName;
    });
    final pending = requests
        .where((r) => r.status == RentalRequestStatus.pending)
        .length;
    final active = requests
        .where(
          (r) =>
              r.status == RentalRequestStatus.active ||
              r.status == RentalRequestStatus.returnRequested,
        )
        .length;
    final completed = requests
        .where((r) => r.status == RentalRequestStatus.completed)
        .length;
    final upcoming = requests
        .where(
          (r) =>
              r.status == RentalRequestStatus.pending ||
              r.status == RentalRequestStatus.approved,
        )
        .length;

    final reviewState = context.watch<ReviewsState>();
    final profileId = isCurrentUser ? user?.id : userId;
    final reviews = role == UserRole.owner
        ? (profileId == null || profileId.isEmpty
              ? reviewState.forOwner(displayName)
              : reviewState.forOwnerId(profileId, fallbackName: displayName))
        : (profileId == null || profileId.isEmpty
              ? reviewState.byRenter(displayName)
              : reviewState.byRenterId(profileId, fallbackName: displayName));
    final average = role == UserRole.owner && reviews.isNotEmpty
        ? reviews.fold<int>(0, (sum, review) => sum + review.rating) /
              reviews.length
        : 0.0;
    final listings = role == UserRole.owner
        ? OwnerListingsStore.instance.items.length
        : 0;
    final favorites = isCurrentUser
        ? context.watch<FavoritesState>().items.length
        : 0;
    final fields = [
      photo != null,
      displayName.isNotEmpty,
      displayCommunity.isNotEmpty,
      phone.isNotEmpty,
      bio.isNotEmpty,
    ];
    final completion = (fields.where((value) => value).length / 5 * 100)
        .round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isCurrentUser ? null : AppBar(title: const Text('Owner Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (isCurrentUser) ...[
              Text(
                'My Profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _Header(
              name: displayName,
              community: displayCommunity,
              role: role,
              email: displayEmail,
              photo: photo,
              verified: isCurrentUser && (user?.identityVerified ?? false),
              editable: isCurrentUser,
              pickPhoto: () => _pickPhoto(context),
              removePhoto: () =>
                  context.read<AuthState>().updateProfileImage(null),
              edit: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: AppSpacing.lg),
              _Completion(
                value: completion,
                missing: [
                  if (photo == null) 'photo',
                  if (phone.isEmpty) 'phone number',
                  if (bio.isEmpty) 'bio',
                ],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _Title('Activity'),
            _StatsGrid(
              stats: role == UserRole.owner
                  ? [
                      _StatData('$listings', 'Listings'),
                      _StatData('$pending', 'Pending'),
                      _StatData('$active', 'Active'),
                      _StatData(
                        reviews.isEmpty ? '—' : average.toStringAsFixed(1),
                        'Rating',
                      ),
                    ]
                  : [
                      _StatData('$upcoming', 'Upcoming'),
                      _StatData('$active', 'Active'),
                      _StatData('$completed', 'Completed'),
                      _StatData('$favorites', 'Saved'),
                    ],
            ),
            if (isCurrentUser) ...[
              const _Title('Quick Access'),
              _Menu(
                icon: role == UserRole.owner
                    ? Icons.inventory_2_outlined
                    : Icons.favorite_border_rounded,
                title: role == UserRole.owner ? 'My Listings' : 'Saved Items',
                subtitle: role == UserRole.owner
                    ? 'Add, edit, and manage rental items.'
                    : '$favorites items saved for later.',
                tap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => role == UserRole.owner
                        ? OwnerListingsScreen(community: displayCommunity)
                        : const FavoritesScreen(),
                  ),
                ),
              ),
              _Menu(
                icon: Icons.receipt_long_outlined,
                title: 'Rental Activity',
                subtitle:
                    '$pending pending, $active active, $completed completed.',
                tap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => _Activity(pending, active, completed),
                ),
              ),
            ],
            const _Title('About'),
            _Panel([
              Text(
                bio.isNotEmpty
                    ? bio
                    : isCurrentUser
                    ? 'Add a bio so your community can know you better.'
                    : 'No bio added yet.',
              ),
              const Divider(height: AppSpacing.xl),
              _Info(
                Icons.mail_outline_rounded,
                displayEmail ?? 'Email not available',
              ),
              const SizedBox(height: 10),
              _Info(
                Icons.phone_outlined,
                phone.isEmpty ? 'Phone number not added' : phone,
              ),
              const SizedBox(height: 10),
              _Info(
                Icons.calendar_today_outlined,
                !isCurrentUser || user?.joinedAt == null
                    ? 'Community member'
                    : 'Member since ${user!.joinedAt!.year}',
              ),
            ]),
            const _Title('Trust & Reputation'),
            _Panel([
              _Info(
                isCurrentUser && user?.identityVerified == true
                    ? Icons.verified_user_outlined
                    : Icons.groups_outlined,
                isCurrentUser && user?.identityVerified == true
                    ? 'Identity verified'
                    : 'Community member',
                color: isCurrentUser && user?.identityVerified == true
                    ? AppColors.success
                    : AppColors.primary,
              ),
              const SizedBox(height: 10),
              _Info(Icons.task_alt_rounded, '$completed successful rentals'),
              if (role == UserRole.owner) ...[
                const SizedBox(height: 10),
                _Info(
                  Icons.star_rounded,
                  reviews.isEmpty
                      ? 'No owner rating yet'
                      : '${average.toStringAsFixed(1)} average rating',
                  color: const Color(0xFFF5A623),
                ),
              ],
            ]),
            _Title(
              role == UserRole.owner ? 'Reviews from Renters' : 'Reviews Given',
            ),
            if (reviews.isEmpty)
              const _EmptyReviews()
            else
              ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReviewCard(review: review),
                ),
              ),
            if (isCurrentUser) ...[
              const _Title('Account & Settings'),
              _Menu(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                subtitle: 'Update your name, community, phone, and bio.',
                tap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _Menu(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'View rental and account updates.',
                tap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(role: role),
                  ),
                ),
              ),
              _Menu(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy & Security',
                subtitle: 'Your contact details stay private.',
                tap: () => _message(
                  context,
                  'Password management will be available in a future update.',
                ),
              ),
              _Menu(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help with rentals and your account.',
                tap: () => _message(context, 'Contact support@rentmark.app.'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthState>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('LOG OUT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String community;
  final UserRole role;
  final String? email;
  final Uint8List? photo;
  final bool verified;
  final bool editable;
  final VoidCallback pickPhoto;
  final VoidCallback removePhoto;
  final VoidCallback edit;
  const _Header({
    required this.name,
    required this.community,
    required this.role,
    required this.email,
    required this.photo,
    required this.verified,
    required this.editable,
    required this.pickPhoto,
    required this.removePhoto,
    required this.edit,
  });

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.primary,
          backgroundImage: photo == null ? null : MemoryImage(photo!),
          child: photo == null
              ? Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        if (editable)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                label: Text(photo == null ? 'ADD PHOTO' : 'CHANGE PHOTO'),
              ),
              if (photo != null)
                TextButton(onPressed: removePhoto, child: const Text('REMOVE')),
            ],
          )
        else
          const SizedBox(height: AppSpacing.md),
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        Text(role.label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        _Info(Icons.location_on_rounded, community, color: AppColors.primary),
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(email!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primarySofter,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.groups_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                verified ? 'Identity verified' : 'Community member',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (editable) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: edit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('EDIT PROFILE'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Completion extends StatelessWidget {
  final int value;
  final List<String> missing;
  final VoidCallback onTap;
  const _Completion({
    required this.value,
    required this.missing,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primarySofter,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: InkWell(
      onTap: value < 100 ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile $value% complete',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (value < 100)
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              backgroundColor: AppColors.surface,
            ),
            if (value < 100) ...[
              const SizedBox(height: 8),
              Text('Add ${missing.join(', ')} to build trust.'),
            ] else ...[
              const SizedBox(height: 8),
              const Text('Your profile is ready for the community.'),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    decoration: _boxDecoration,
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class _StatData {
  final String value;
  final String label;
  const _StatData(this.value, this.label);
}

class _StatsGrid extends StatelessWidget {
  final List<_StatData> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: stats
            .map(
              (stat) =>
                  SizedBox(width: width, child: _Stat(stat.value, stat.label)),
            )
            .toList(),
      );
    },
  );
}

class _Menu extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback tap;
  const _Menu({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tap,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: _boxDecoration,
    child: ListTile(
      onTap: tap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySofter,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _Panel extends StatelessWidget {
  final List<Widget> children;
  const _Panel(this.children);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: _boxDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.card,
    ),
    child: child,
  );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Info(this.icon, this.label, {this.color = AppColors.textSecondary});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Flexible(child: Text(label)),
    ],
  );
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: _boxDecoration,
    child: const Center(child: Text('No reviews yet.')),
  );
}

class _Activity extends StatelessWidget {
  final int pending;
  final int active;
  final int completed;
  const _Activity(this.pending, this.active, this.completed);
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rental Activity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _Info(Icons.schedule_rounded, '$pending pending requests'),
          const SizedBox(height: 12),
          _Info(Icons.play_circle_outline_rounded, '$active active rentals'),
          const SizedBox(height: 12),
          _Info(
            Icons.check_circle_outline_rounded,
            '$completed completed rentals',
          ),
        ],
      ),
    ),
  );
}

final _boxDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: AppColors.border),
);
