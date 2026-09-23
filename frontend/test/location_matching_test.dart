import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/location_matching.dart';

void main() {
  test('matches the same community regardless of case and punctuation', () {
    expect(
      isItemInCommunity(
        userCommunity: 'Matina, Davao City',
        itemCommunity: 'matina - davao city',
        itemCity: '',
      ),
      isTrue,
    );
  });

  test('matches a structured profile area to the listing city', () {
    expect(
      isItemInCommunity(
        userCommunity: 'Barangay Zone 1, Digos City',
        itemCommunity: 'Davao Community',
        itemCity: 'Digos City',
      ),
      isTrue,
    );
  });

  test('does not recommend an item from another city', () {
    expect(
      isItemInCommunity(
        userCommunity: 'Barangay Zone 1, Digos City',
        itemCommunity: 'Davao Community',
        itemCity: 'Davao City',
      ),
      isFalse,
    );
  });
}
