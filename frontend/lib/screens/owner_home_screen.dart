import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/rental_pricing.dart';

import 'package:provider/provider.dart';

import '../data/owner_listings_store.dart';
import '../models/rental_item.dart';
import '../models/rental_request.dart';
import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../state/notifications_state.dart';
import '../state/rental_requests_state.dart';
import '../theme/app_theme.dart';
import '../widgets/item_image.dart';
import '../widgets/rentmark_logo.dart';
import '../widgets/request_status_badge.dart';
import 'add_edit_item_screen.dart';
import 'notifications_screen.dart';
import 'owner_listings_screen.dart';
import 'owner_request_details_screen.dart';
import 'owner_requests_screen.dart';
import 'user_profile_screen.dart';

class OwnerHomeScreen extends StatelessWidget {
  final String ownerName;
  final String community;
  final Uint8List? profileImageBytes;

  const OwnerHomeScreen({
    super.key,
    required this.ownerName,
    required this.community,
    this.profileImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    final name = user?.name ?? ownerName;
    final location = user?.community ?? community;
    final photo = user?.profileImageBytes ?? profileImageBytes;
    final requests = context.watch<RentalRequestsState>().requests;
    final unread = context.watch<NotificationsState>().unreadFor(
      UserRole.owner,
    );
    final store = OwnerListingsStore.instance;

    final pending = requests
        .where((r) => r.status == RentalRequestStatus.pending)
        .length;
    final approved = requests
        .where((r) => r.status == RentalRequestStatus.approved)
        .length;
    final active = requests
        .where(
          (r) =>
              r.status == RentalRequestStatus.active ||
              r.status == RentalRequestStatus.returnRequested,
        )
        .length;
    final returns = requests
        .where((r) => r.status == RentalRequestStatus.returnRequested)
        .length;
    final completed = requests
        .where((r) => r.status == RentalRequestStatus.completed)
        .length;
    final earnings = requests
        .where((r) => r.status == RentalRequestStatus.completed)
        .fold<double>(0, (sum, request) => sum + request.estimatedTotal);

    void openRequests() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerRequestsScreen()),
    );

    void openListings() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerListingsScreen(community: location),
      ),
    );

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final listings = store.items;
        final available = listings
            .where(
              (item) => item.availability != AvailabilityStatus.unavailable,
            )
            .length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _Header(
                  photo: photo,
                  unread: unread,
                  notifications: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsScreen(role: UserRole.owner),
                    ),
                  ),
                  profile: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        name: name,
                        community: location,
                        role: UserRole.owner,
                        isCurrentUser: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Welcome back, $name',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(location),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _Earnings(
                  amount: earnings,
                  completed: completed,
                  active: active,
                ),
                const _SectionTitle('Overview'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _Metric(
                      Icons.schedule_rounded,
                      '$pending',
                      'Pending requests',
                      const Color(0xFFF5A623),
                    ),
                    _Metric(
                      Icons.play_circle_outline_rounded,
                      '$active',
                      'Active rentals',
                      AppColors.primary,
                    ),
                    _Metric(
                      Icons.inventory_2_outlined,
                      listings.length.toString(),
                      'Total listings',
                      const Color(0xFF7B61FF),
                    ),
                    _Metric(
                      Icons.check_circle_outline_rounded,
                      '$available',
                      'Available items',
                      AppColors.success,
                    ),
                  ],
                ),
                if (pending > 0 || returns > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _Attention(
                    pending: pending,
                    returns: returns,
                    onTap: openRequests,
                  ),
                ],
                const _SectionTitle('Manage'),
                _MenuCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Rental Requests',
                  subtitle:
                      '$pending pending · $approved approved · $active active',
                  count: pending,
                  onTap: openRequests,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SmallAction(
                        icon: Icons.inventory_2_rounded,
                        title: 'My Listings',
                        subtitle: 'Manage ${listings.length} items',
                        onTap: openListings,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _SmallAction(
                        icon: Icons.add_box_rounded,
                        title: 'Add Item',
                        subtitle: 'Create a listing',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditItemScreen(community: location),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const _SectionTitle('Recent Requests'),
                if (requests.isEmpty)
                  const _EmptyCard(
                    icon: Icons.inbox_outlined,
                    text: 'New rental requests will appear here.',
                  )
                else
                  ...requests
                      .take(3)
                      .map(
                        (request) => _RecentRequest(
                          request: request,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OwnerRequestDetailsScreen(request: request),
                            ),
                          ),
                        ),
                      ),
                const _SectionTitle('Listing Health'),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$available available out of ${listings.length}',
                      ),
                    ),
                    TextButton(
                      onPressed: openListings,
                      child: const Text('MANAGE'),
                    ),
                  ],
                ),
                if (listings.isEmpty)
                  const _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    text: 'Add your first listing to start earning.',
                  )
                else
                  ...listings
                      .take(2)
                      .map(
                        (item) => _ListingRow(
                          name: item.name,
                          imageUrl: item.imageUrl,
                          icon: item.icon,
                          price: item.priceLabel,
                          available:
                              item.availability !=
                              AvailabilityStatus.unavailable,
                          onTap: openListings,
                        ),
                      ),
                const SizedBox(height: AppSpacing.lg),
                const _OwnerTip(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final Uint8List? photo;
  final int unread;
  final VoidCallback notifications;
  final VoidCallback profile;
  const _Header({
    required this.photo,
    required this.unread,
    required this.notifications,
    required this.profile,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: RentMarkLogo(size: 36)),
      Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: notifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          if (unread > 0)
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: AppColors.error,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
        ],
      ),
      InkWell(
        onTap: profile,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primarySofter,
          backgroundImage: photo == null ? null : MemoryImage(photo!),
          child: photo == null
              ? const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textPrimary,
                )
              : null,
        ),
      ),
    ],
  );
}

class _Earnings extends StatelessWidget {
  final num amount;
  final int completed;
  final int active;
  const _Earnings({
    required this.amount,
    required this.completed,
    required this.active,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.heroGradient),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ESTIMATED EARNINGS',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          formatPesos(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '$completed completed · $active active',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _Metric(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: _cardDecoration,
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Attention extends StatelessWidget {
  final int pending;
  final int returns;
  final VoidCallback onTap;
  const _Attention({
    required this.pending,
    required this.returns,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high_rounded, color: Color(0xFFF5A623)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs your attention',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  returns > 0
                      ? '$returns returns need confirmation'
                      : '$pending requests are waiting for review',
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _raisedDecoration,
      child: Row(
        children: [
          _ActionIcon(icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (count > 0)
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SmallAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _raisedDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionIcon(icon),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  const _ActionIcon(this.icon);
  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Icon(icon, color: AppColors.primary),
  );
}

class _RecentRequest extends StatelessWidget {
  final RentalRequest request;
  final VoidCallback onTap;
  const _RecentRequest({required this.request, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: _cardDecoration,
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySofter,
        child: Icon(request.item.icon, color: AppColors.primary),
      ),
      title: Text(
        request.item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${request.renterName} · ${request.rentalPeriodLabel}'),
      trailing: RequestStatusBadge(status: request.status),
    ),
  );
}

class _ListingRow extends StatelessWidget {
  final String name;
  final String imageUrl;
  final IconData icon;
  final String price;
  final bool available;
  final VoidCallback onTap;
  const _ListingRow({
    required this.name,
    required this.imageUrl,
    required this.icon,
    required this.price,
    required this.available,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: _cardDecoration,
    child: ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ItemImage(imageUrl: imageUrl, icon: icon, width: 48, height: 48),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(price),
      trailing: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: available ? AppColors.success : AppColors.error,
        ),
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: _cardDecoration,
    child: Column(
      children: [
        Icon(icon, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _OwnerTip extends StatelessWidget {
  const _OwnerTip();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Owner tip: clear photos and complete descriptions help listings receive more requests.',
          ),
        ),
      ],
    ),
  );
}

final _cardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.md),
  border: Border.all(color: AppColors.border),
);

final _raisedDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  boxShadow: AppShadows.card,
);
