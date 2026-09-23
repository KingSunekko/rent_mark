import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/owner_listing.dart';
import 'package:rent_mark/models/rental_request.dart';
import 'package:rent_mark/models/rental_pricing.dart';

OwnerListing ownerListing({int? discount}) => OwnerListing.fromJson({
  'id': 'item',
  'owner_id': 'owner',
  'owner_name': 'Owner',
  'name': 'Camera',
  'description': 'A camera for events.',
  'category': 'electronics',
  'condition': 'Good',
  'price_per_day': 99,
  'availability': 'available',
  'community': 'Davao',
  'moderation_status': 'active',
  'discount_percent': ?discount,
});

void main() {
  test('old listings and disabled discounts retain the regular rate', () {
    final listing = ownerListing();
    expect(listing.discountPercent, 0);
    expect(listing.toRentalItem().totalForDays(3), 297);
    expect(listing.priceLabel, '₱99 / day');
  });

  test('daily discount preserves centavos and inclusive rental totals', () {
    final item = ownerListing(discount: 15).toRentalItem();
    expect(item.dailyPriceCentavos, 8415);
    expect(item.priceLabel, '₱84.15 / day');
    final request = RentalRequest(
      id: 'request',
      item: item,
      renterName: 'Renter',
      startDate: DateTime(2026, 9, 7),
      endDate: DateTime(2026, 9, 9),
      message: '',
      requestedAt: DateTime(2026, 9, 7),
    );
    expect(request.durationDays, 3);
    expect(request.estimatedTotalLabel, '₱252.45');
    expect(item.totalForDays(1), 84.15);
  });

  test('owner edits do not reprice an existing request snapshot', () {
    final listing = ownerListing(discount: 20);
    final snapshot = listing.toRentalItem();
    listing.discountPercent = 0;
    listing.pricePerDay = 500;
    expect(snapshot.priceLabel, '₱79.20 / day');
    expect(listing.toRentalItem().priceLabel, '₱500 / day');
    expect(listing.toApiJson(imagePaths: [])['discount_percent'], 0);
  });

  test('discount serializes and smallest price remains positive', () {
    final listing = ownerListing(discount: 20);
    expect(listing.toApiJson(imagePaths: [])['discount_percent'], 20);
    expect(discountedDailyCentavos(1, 20), 80);
    expect(formatPesos(0.8), '₱0.80');
  });
}
