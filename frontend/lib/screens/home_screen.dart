import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../data/owner_listings_store.dart';
import '../models/rental_item.dart';
import '../state/auth_state.dart';
import '../state/favorites_state.dart';
import '../state/rental_requests_state.dart';
import '../models/rental_request.dart';
import '../models/location_matching.dart';
import '../widgets/item_discovery_header.dart';
import '../widgets/rentmark_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/item_card.dart';
import '../widgets/featured_item_card.dart';
import '../widgets/compact_item_card.dart';
import '../widgets/skeleton_loading.dart';
import '../screens/item_details_screen.dart';
import '../screens/search_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/user_role.dart';

/// The Renter Item Discovery / Home screen — replaces the Phase 1 Home
/// placeholder. Header → Search → Categories → Items Near You → Featured
/// → Popular. Items are the center of the screen throughout.
class HomeScreen extends StatefulWidget {
  final String userName;
  final String community;
  final Uint8List? profileImageBytes;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.community,
    this.profileImageBytes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ItemCategory _selectedCategory = ItemCategory.all;
  bool _isLoading = true;
  final _ownerListings = OwnerListingsStore.instance;

  @override
  void initState() {
    super.initState();
    _ownerListings.addListener(_refreshListings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ownerListings.loadPublic(context.read<AuthState>().accessToken);
      }
    });
    // Purely visual mock loading state — no real network request.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _ownerListings.removeListener(_refreshListings);
    super.dispose();
  }

  void _refreshListings() => setState(() {});

  void _openItem(RentalItem item) {
    context.read<FavoritesState>().recordViewed(item);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)));
  }

  void _openSearch() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  void _resetCategory() => setState(() => _selectedCategory = ItemCategory.all);

  Future<void> _retryRecommendations() async {
    await _ownerListings.loadPublic(context.read<AuthState>().accessToken);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthState>().currentUser;
    final currentProfileImageBytes =
        currentUser?.profileImageBytes ?? widget.profileImageBytes;
    final currentUserName = currentUser?.name ?? widget.userName;
    final currentCommunity = currentUser?.community ?? widget.community;
    final catalog = _ownerListings.discoveryItems
        .where((item) => item.availability != AvailabilityStatus.unavailable)
        .map((item) => item.toRentalItem())
        .toList();
    final nearbyCatalog = catalog
        .where(
          (item) => isItemInCommunity(
            userCommunity: currentCommunity,
            itemCommunity: item.community,
            itemCity: item.city,
          ),
        )
        .toList();
    final nearYou = _selectedCategory == ItemCategory.all
        ? nearbyCatalog
        : nearbyCatalog
              .where((item) => item.category == _selectedCategory)
              .toList();
    final featured = catalog.take(5).toList();
    final popular = List<RentalItem>.of(catalog)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final favoritesState = context.watch<FavoritesState>();
    final recentlyViewed = favoritesState.recentlyViewed.take(5).toList();
    final saved = favoritesState.items.take(5).toList();
    final renterRequests = context
        .watch<RentalRequestsState>()
        .requests
        .where(
          (request) => request.renterId.isNotEmpty
              ? request.renterId == currentUser?.id
              : request.renterName == currentUserName,
        )
        .toList();
    RentalRequest? activeRental;
    for (final request in renterRequests) {
      if (request.status == RentalRequestStatus.active ||
          request.status == RentalRequestStatus.returnRequested) {
        activeRental = request;
        break;
      }
    }
    final activeRequest = activeRental;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            setState(() => _isLoading = true);
            await _ownerListings.loadPublic(
              context.read<AuthState>().accessToken,
            );
            await Future.delayed(const Duration(milliseconds: 700));
            if (mounted) setState(() => _isLoading = false);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              ItemDiscoveryHeader(
                community: currentCommunity,
                userName: currentUserName,
                profileImageBytes: currentProfileImageBytes,
                onNotificationTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const NotificationsScreen(role: UserRole.renter),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RentMarkSearchBar(readOnly: true, onTap: _openSearch),
              if (activeRequest != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ActiveRentalBanner(
                  request: activeRequest,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ItemDetailsScreen(item: activeRequest.item),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Categories
              Text('Categories', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ItemCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final category = ItemCategory.values[i];
                    return CategoryChip(
                      category: category,
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Items Near You
              SectionHeader(
                title: 'Recommended Near You',
                subtitle: 'Available items from your community',
                actionLabel: 'See All',
                onAction: _openSearch,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 302,
                child: _isLoading
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (_, _) => const SkeletonLargeCard(),
                      )
                    : _ownerListings.error != null && catalog.isEmpty
                    ? _InlineCategoryEmptyState(
                        message: 'Recommended items could not be loaded.',
                        actionLabel: 'RETRY',
                        onAction: _retryRecommendations,
                      )
                    : nearYou.isEmpty
                    ? _InlineCategoryEmptyState(
                        message: _selectedCategory == ItemCategory.all
                            ? 'No available items match your area yet.'
                            : 'No nearby items match this category.',
                        actionLabel: _selectedCategory == ItemCategory.all
                            ? 'VIEW ALL ITEMS'
                            : 'CLEAR CATEGORY',
                        onAction: _selectedCategory == ItemCategory.all
                            ? _openSearch
                            : _resetCategory,
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: nearYou.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => ItemCard(
                          item: nearYou[i],
                          onTap: () => _openItem(nearYou[i]),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (recentlyViewed.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recently Viewed',
                  actionLabel: 'Clear',
                  onAction: favoritesState.clearRecentlyViewed,
                ),
                const SizedBox(height: AppSpacing.md),
                ...recentlyViewed.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CompactItemCard(
                      item: item,
                      onTap: () => _openItem(item),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (saved.isNotEmpty) ...[
                const SectionHeader(title: 'Saved Items'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 182,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: saved.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, index) => FeaturedItemCard(
                      item: saved[index],
                      onTap: () => _openItem(saved[index]),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Featured Items
              SectionHeader(title: 'Featured Items'),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 182,
                child: _isLoading
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, _) => const SkeletonBox(
                          width: 148,
                          height: 182,
                          radius: AppRadius.md,
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => FeaturedItemCard(
                          item: featured[i],
                          onTap: () => _openItem(featured[i]),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Popular / More Items
              SectionHeader(title: 'More Items'),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm + 2),
                      child: SkeletonCompactCard(),
                    ),
                  ),
                )
              else
                Column(
                  children: popular
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm + 2,
                          ),
                          child: CompactItemCard(
                            item: item,
                            onTap: () => _openItem(item),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveRentalBanner extends StatelessWidget {
  final RentalRequest request;
  final VoidCallback onTap;
  const _ActiveRentalBanner({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.timelapse_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active rental',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  request.item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(request.rentalPeriodLabel),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

/// Compact inline empty state sized to sit inside the horizontal "Items
/// Near You" row when the selected category has nothing in it.
class _InlineCategoryEmptyState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineCategoryEmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No items available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
