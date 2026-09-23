import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/data/owner_listings_store.dart';
import 'package:rent_mark/models/owner_listing.dart';
import 'package:rent_mark/models/rental_item.dart';

void main() {
  test('backend listing keeps authoritative image paths', () {
    final listing = OwnerListing.fromJson({
      'id': 'item-1',
      'owner_id': 'owner-1',
      'owner_name': 'Sample Owner',
      'name': 'Camera',
      'description': 'A camera for community events.',
      'category': 'electronics',
      'condition': 'Good',
      'price_per_day': 500,
      'availability': 'available',
      'community': 'Davao Community',
      'image_urls': ['https://example.com/camera.jpg'],
      'image_paths': ['owner-1/camera.jpg'],
      'moderation_status': 'active',
    });

    expect(listing.storagePaths, ['owner-1/camera.jpg']);
    expect(listing.toApiJson(imagePaths: listing.storagePaths)['image_paths'], [
      'owner-1/camera.jpg',
    ]);
  });

  test('resetSession removes all account-scoped listings', () {
    final store = OwnerListingsStore.instance;
    store.add(
      OwnerListing(
        id: 'private-session-item',
        name: 'Private item',
        category: ItemCategory.other,
        pricePerDay: 100,
        description: 'Temporary listing for an account session.',
        condition: 'Good',
        availability: AvailabilityStatus.available,
        imageUrl: '',
        community: 'Davao Community',
      ),
    );

    store.resetSession();

    expect(
      store.items.any((item) => item.id == 'private-session-item'),
      isFalse,
    );
    expect(store.items, isEmpty);
  });
}
