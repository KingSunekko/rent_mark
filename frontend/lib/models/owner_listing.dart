import 'package:flutter/material.dart';

import 'rental_item.dart';
import 'rental_pricing.dart';

enum ListingModerationStatus { active, hidden, underReview }

class OwnerListing {
  final String id;
  String name;
  ItemCategory category;
  int pricePerDay;
  int discountPercent;
  String description;
  String condition;
  AvailabilityStatus availability;
  String imageUrl;
  List<String> galleryUrls;
  List<String> storagePaths;
  String community;
  String city;
  String barangay;
  String meetingPoint;
  String pickupInstructions;
  final String ownerId;
  final String ownerName;
  ListingModerationStatus moderationStatus;

  OwnerListing({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerDay,
    this.discountPercent = 0,
    required this.description,
    required this.condition,
    required this.availability,
    required this.imageUrl,
    this.galleryUrls = const [],
    this.storagePaths = const [],
    required this.community,
    this.city = '',
    this.barangay = '',
    this.meetingPoint = '',
    this.pickupInstructions = '',
    this.ownerId = 'user-owner-001',
    this.ownerName = 'Sample Owner',
    this.moderationStatus = ListingModerationStatus.active,
  });

  factory OwnerListing.fromJson(Map<String, dynamic> json) {
    final images = (json['image_urls'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();
    return OwnerListing(
      id: json['id'].toString(),
      name: json['name'].toString(),
      category: ItemCategory.values.byName(json['category'].toString()),
      pricePerDay: json['price_per_day'] as int,
      discountPercent: json['discount_percent'] as int? ?? 0,
      description: json['description'].toString(),
      condition: json['condition'].toString(),
      availability: AvailabilityStatus.values.byName(
        json['availability'].toString(),
      ),
      imageUrl: images.isEmpty ? '' : images.first,
      galleryUrls: images,
      storagePaths: (json['image_paths'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      community: json['community'].toString(),
      city: json['city'] as String? ?? '',
      barangay: json['barangay'] as String? ?? '',
      meetingPoint: json['meeting_point'] as String? ?? '',
      pickupInstructions: json['pickup_instructions'] as String? ?? '',
      ownerId: json['owner_id'].toString(),
      ownerName: json['owner_name'].toString(),
      moderationStatus: ListingModerationStatus.values.byName(
        json['moderation_status'].toString(),
      ),
    );
  }

  Map<String, Object> toApiJson({required List<String> imagePaths}) => {
    'name': name,
    'description': description,
    'category': category.name,
    'condition': condition,
    'price_per_day': pricePerDay,
    'discount_percent': discountPercent,
    'availability': availability.name,
    'image_paths': imagePaths,
    'city': city.trim(),
    'barangay': barangay.trim(),
    'meeting_point': meetingPoint.trim(),
    'pickup_instructions': pickupInstructions.trim(),
  };

  IconData get icon => category.icon;

  RentalItem toRentalItem() => RentalItem(
    id: id,
    name: name,
    icon: icon,
    imageUrl: imageUrl.isEmpty ? null : imageUrl,
    galleryUrls: galleryUrls,
    category: category,
    pricePerDay: pricePerDay,
    discountPercent: discountPercent,
    rating: 0,
    availability: moderationStatus == ListingModerationStatus.active
        ? availability
        : AvailabilityStatus.unavailable,
    distanceKm: 0.5,
    community: community,
    city: city,
    barangay: barangay,
    meetingPoint: meetingPoint,
    pickupInstructions: pickupInstructions,
    description: description,
    condition: condition,
    ownerName: ownerName,
    ownerId: ownerId,
  );
  String get priceLabel =>
      '${formatPesos(discountedDailyCentavos(pricePerDay, discountPercent) / 100)} / day';
}
