import 'package:flutter/material.dart';

import 'rental_pricing.dart';

/// The categories items can belong to. `all` is a UI-only filter value,
/// never assigned to an actual item.
enum ItemCategory {
  all,
  electronics,
  tools,
  sports,
  school,
  camping,
  events,
  appliances,
  other,
}

extension ItemCategoryLabel on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.all:
        return 'All';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.tools:
        return 'Tools';
      case ItemCategory.sports:
        return 'Sports';
      case ItemCategory.school:
        return 'School';
      case ItemCategory.camping:
        return 'Camping';
      case ItemCategory.events:
        return 'Events';
      case ItemCategory.appliances:
        return 'Appliances';
      case ItemCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.all:
        return Icons.apps_rounded;
      case ItemCategory.electronics:
        return Icons.camera_alt_rounded;
      case ItemCategory.tools:
        return Icons.hardware_rounded;
      case ItemCategory.sports:
        return Icons.sports_basketball_rounded;
      case ItemCategory.school:
        return Icons.calculate_rounded;
      case ItemCategory.camping:
        return Icons.terrain_rounded;
      case ItemCategory.events:
        return Icons.videocam_rounded;
      case ItemCategory.appliances:
        return Icons.kitchen_rounded;
      case ItemCategory.other:
        return Icons.category_rounded;
    }
  }
}

/// Availability state for a rental item. Supports the vocabulary called
/// for in the spec ("Available", "Available today", "Unavailable") even
/// though current mock data only uses `available`.
enum AvailabilityStatus { available, availableToday, unavailable }

extension AvailabilityStatusLabel on AvailabilityStatus {
  String get label {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.availableToday:
        return 'Available today';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
    }
  }
}

/// A rentable item displayed from the authenticated backend catalog.
///
/// [imageUrl] is optional: when present, [ItemCard]/[FeaturedItemCard]
/// load it with a graceful fallback to the icon tile if it fails or is
/// absent, so real photography can be dropped in later without touching
/// card layout code. [galleryUrls] holds the full Item Details photo set
/// (starting with [imageUrl]); cards only ever use the primary image.
class RentalItem {
  final String id;
  final String name;
  final IconData icon;
  final String? imageUrl;
  final List<String> galleryUrls;
  final ItemCategory category;
  final int pricePerDay;
  final int discountPercent;
  final double rating;
  final AvailabilityStatus availability;
  final double distanceKm;
  final String community;
  final String city;
  final String barangay;
  final String meetingPoint;
  final String pickupInstructions;
  final bool featured;
  final bool popular;

  // Phase 3 — Item Details fields.
  final String description;
  final String condition;
  final String rentalType;
  final String ownerName;
  final String ownerId;
  final double ownerRating;

  const RentalItem({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
    this.galleryUrls = const [],
    required this.category,
    required this.pricePerDay,
    this.discountPercent = 0,
    required this.rating,
    required this.availability,
    required this.distanceKm,
    required this.community,
    this.city = '',
    this.barangay = '',
    this.meetingPoint = '',
    this.pickupInstructions = '',
    this.featured = false,
    this.popular = false,
    this.description = '',
    this.condition = 'Good',
    this.rentalType = 'Daily',
    this.ownerName = 'RentMark Community Member',
    this.ownerId = 'user-owner-001',
    this.ownerRating = 4.8,
  });

  bool get isAvailable => availability != AvailabilityStatus.unavailable;

  int get dailyPriceCentavos =>
      discountedDailyCentavos(pricePerDay, discountPercent);
  double get discountedPricePerDay => dailyPriceCentavos / 100;
  double totalForDays(int days) => dailyPriceCentavos * days / 100;
  String get originalPriceLabel => '${formatPesos(pricePerDay)} / day';
  String get priceLabel => '${formatPesos(discountedPricePerDay)} / day';
  String get priceLabelCompact => '${formatPesos(discountedPricePerDay)}/day';
  // Coordinates are not collected yet; never present mock distances as measured.
  String get distanceLabel => 'Area only';
  String get locationLabel =>
      [
        barangay.trim(),
        city.trim(),
      ].where((value) => value.isNotEmpty).join(', ').isNotEmpty
      ? [
          barangay.trim(),
          city.trim(),
        ].where((value) => value.isNotEmpty).join(', ')
      : community;
  String get mapSearchQuery => meetingPoint.trim().isEmpty
      ? ''
      : [meetingPoint.trim(), locationLabel, 'Philippines'].join(', ');
}
