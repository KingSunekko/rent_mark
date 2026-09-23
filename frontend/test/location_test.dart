import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/owner_listing.dart';
import 'package:rent_mark/models/rental_item.dart';
import 'package:rent_mark/services/maps_service.dart';
import 'package:rent_mark/widgets/location_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rentmark/maps');
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  final listing = OwnerListing(
    id: 'item',
    name: 'Camera',
    category: ItemCategory.electronics,
    pricePerDay: 99,
    description: 'A camera for events.',
    condition: 'Good',
    availability: AvailabilityStatus.available,
    imageUrl: '',
    community: 'Davao Community',
    city: 'Davao City',
    barangay: 'Matina',
    meetingPoint: 'Barangay hall',
    pickupInstructions: 'Main entrance.',
  );

  test('location serializes and no mock distance is presented', () {
    expect(listing.toApiJson(imagePaths: [])['city'], 'Davao City');
    final item = listing.toRentalItem();
    expect(item.locationLabel, 'Matina, Davao City');
    expect(
      item.mapSearchQuery,
      'Barangay hall, Matina, Davao City, Philippines',
    );
    expect(item.distanceLabel, 'Area only');
  });

  test(
    'map launch uses a public meeting query and handles unavailable apps',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'openSearch');
            expect(
              (call.arguments as Map)['query'],
              listing.toRentalItem().mapSearchQuery,
            );
            return true;
          });
      expect(
        await MapsService.openMeetingPoint(
          listing.toRentalItem().mapSearchQuery,
        ),
        isTrue,
      );
      expect(await MapsService.openMeetingPoint(''), isFalse);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw PlatformException(code: 'unavailable'),
          );
      expect(await MapsService.openMeetingPoint('Hall'), isFalse);
    },
  );

  testWidgets('location shows public instructions and a map action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LocationSection(item: listing.toRentalItem())),
      ),
    );
    expect(find.text('Matina, Davao City'), findsOneWidget);
    expect(find.text('Main entrance.'), findsOneWidget);
    expect(find.text('Open in Google Maps'), findsOneWidget);
    expect(find.textContaining('km away'), findsNothing);
  });
}
