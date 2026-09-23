import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/owner_listings_store.dart';
import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import '../models/rental_request.dart';
import '../widgets/item_image_gallery.dart';
import '../widgets/favorite_button.dart';
import '../widgets/item_header.dart';
import '../widgets/item_price.dart';
import '../widgets/item_description.dart';
import '../widgets/item_information.dart';
import '../widgets/location_section.dart';
import '../widgets/owner_preview.dart';
import '../widgets/bottom_rental_action.dart';
import 'rental_request_screen.dart';
import 'user_profile_screen.dart';
import '../models/user_role.dart';
import '../state/reviews_state.dart';
import '../state/favorites_state.dart';
import '../state/rental_requests_state.dart';
import '../widgets/compact_item_card.dart';

/// The single reusable Item Details screen. Every entry point from Phase
/// 2 (Home, Search, category filtering, Near You) opens this same
/// screen — no separate details screens per source.
///
/// Shows everything a renter needs to know before renting: photos, name,
/// price, availability, rating, description, condition, location, and a
/// short owner preview. "Request to Rent" opens the Phase 4 Rental
/// Request screen.
class ItemDetailsScreen extends StatefulWidget {
  final RentalItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  void _openRentalRequest() {
    if (widget.item.availability == AvailabilityStatus.unavailable) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RentalRequestScreen(item: widget.item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final favorites = context.watch<FavoritesState>();
    final requests = context.watch<RentalRequestsState>().requests;
    final reviewState = context.watch<ReviewsState>();
    final ownerReviews = reviewState.forOwner(item.ownerName);
    final itemReviews = reviewState.forItem(item.id);
    final displayedItemRating = itemReviews.isEmpty
        ? item.rating
        : itemReviews.fold<int>(0, (sum, review) => sum + review.rating) /
              itemReviews.length;
    final displayedOwnerRating = ownerReviews.isEmpty
        ? item.ownerRating
        : reviewState.averageForOwner(item.ownerName);
    final gallery = item.galleryUrls.isNotEmpty
        ? item.galleryUrls
        : (item.imageUrl != null ? [item.imageUrl!] : <String>[]);
    final unavailableDates = requests
        .where(
          (request) =>
              request.item.id == item.id &&
              (request.status == RentalRequestStatus.approved ||
                  request.status == RentalRequestStatus.active ||
                  request.status == RentalRequestStatus.returnRequested),
        )
        .toList();
    final ownerCompleted = requests
        .where(
          (request) =>
              request.item.ownerName == item.ownerName &&
              request.status == RentalRequestStatus.completed,
        )
        .length;
    final similar = OwnerListingsStore.instance.discoveryItems
        .map((listing) => listing.toRentalItem())
        .where(
          (candidate) =>
              candidate.id != item.id && candidate.category == item.category,
        )
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ItemImageGallery(
                        imageUrls: gallery,
                        fallbackIcon: item.icon,
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RoundIconButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                              Row(
                                children: [
                                  _RoundIconButton(
                                    icon: Icons.share_outlined,
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: '${item.name} on RentMark',
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Item link copied.'),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  FavoriteButton(
                                    favorited: favorites.contains(item.id),
                                    onTap: () => favorites.toggle(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemHeader(
                          name: item.name,
                          category: item.category.label,
                          rating: displayedItemRating,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ItemPrice(
                          priceLabel: item.priceLabel,
                          originalPriceLabel: item.originalPriceLabel,
                          discountPercent: item.discountPercent,
                          availability: item.availability,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ItemDescription(description: item.description),
                        const SizedBox(height: AppSpacing.xl),
                        ItemInformation(
                          condition: item.condition,
                          category: item.category.label,
                          availabilityLabel: item.availability.label,
                          rentalType: item.rentalType,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        LocationSection(item: item),
                        const SizedBox(height: AppSpacing.xl),
                        OwnerPreview(
                          ownerName: item.ownerName,
                          ownerRating: displayedOwnerRating,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                name: item.ownerName,
                                community: item.community,
                                role: UserRole.owner,
                                userId: item.ownerId,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Usually responds within a few hours · $ownerCompleted completed rentals',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Rental Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _RentalGuidance(),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Unavailable Dates',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _UnavailableDates(requests: unavailableDates),
                        if (similar.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Similar Items',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...similar.map(
                            (candidate) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: CompactItemCard(
                                item: candidate,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailsScreen(item: candidate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomRentalAction(
            priceLabel: item.priceLabel,
            onRequestTap: _openRentalRequest,
            enabled: item.availability != AvailabilityStatus.unavailable,
            disabledReason: 'CURRENTLY UNAVAILABLE',
          ),
        ],
      ),
    );
  }
}

class _RentalGuidance extends StatelessWidget {
  const _RentalGuidance();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        _GuidanceRow(
          Icons.handshake_outlined,
          'Pickup & return',
          'Arrange a safe community meetup with the owner.',
        ),
        Divider(height: AppSpacing.xl),
        _GuidanceRow(
          Icons.shield_outlined,
          'Rental rules',
          'Return the item clean and in the same condition.',
        ),
        Divider(height: AppSpacing.xl),
        _GuidanceRow(
          Icons.payments_outlined,
          'Deposit',
          'Any deposit is agreed directly with the owner.',
        ),
      ],
    ),
  );
}

class _GuidanceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _GuidanceRow(this.icon, this.title, this.message);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(message),
          ],
        ),
      ),
    ],
  );
}

class _UnavailableDates extends StatelessWidget {
  final List<RentalRequest> requests;
  const _UnavailableDates({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F0),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Text('No blocked dates. This item is open for requests.'),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: requests
          .map(
            (request) => Chip(
              avatar: const Icon(Icons.event_busy_outlined, size: 17),
              label: Text(request.rentalPeriodLabel),
            ),
          )
          .toList(),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: AppColors.textPrimary),
      ),
    );
  }
}
