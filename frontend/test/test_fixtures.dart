import 'package:flutter/material.dart';
import 'package:rent_mark/models/rental_item.dart';

const testRentalItem = RentalItem(
  id: 'item-test',
  name: 'Test Camera',
  icon: Icons.camera_alt_outlined,
  category: ItemCategory.electronics,
  pricePerDay: 500,
  rating: 4.8,
  availability: AvailabilityStatus.available,
  distanceKm: 0,
  community: 'Davao',
  description: 'A test fixture used by the frontend regression suite.',
  ownerName: 'Test Owner',
  ownerId: 'owner-test',
);
