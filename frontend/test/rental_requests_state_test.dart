import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/rental_request.dart';
import 'package:rent_mark/state/rental_requests_state.dart';

import 'test_fixtures.dart';

void main() {
  test('rental follows only valid status transitions', () {
    final state = RentalRequestsState();
    final request = state.submit(
      build: (id) => RentalRequest(
        id: id,
        item: testRentalItem,
        renterId: 'user-renter-test',
        ownerId: 'user-owner-001',
        renterName: 'Test Renter',
        startDate: DateTime(2030, 1, 1),
        endDate: DateTime(2030, 1, 2),
        message: '',
        requestedAt: DateTime(2029, 12, 1),
      ),
    );

    state.startRental(request);
    expect(request.status, RentalRequestStatus.pending);
    state.approve(request);
    state.startRental(request);
    state.requestReturn(request);
    state.confirmReturn(request);
    expect(request.status, RentalRequestStatus.completed);
  });

  test('overlapping dates are detected for open rentals', () {
    final state = RentalRequestsState();
    final request = state.submit(
      build: (id) => RentalRequest(
        id: id,
        item: testRentalItem,
        renterName: 'Test Renter',
        startDate: DateTime(2031, 5, 10),
        endDate: DateTime(2031, 5, 12),
        message: '',
        requestedAt: DateTime(2031, 5, 1),
      ),
    );
    state.approve(request);

    expect(
      state.hasDateConflict(
        itemId: request.item.id,
        startDate: DateTime(2031, 5, 11),
        endDate: DateTime(2031, 5, 14),
      ),
      isTrue,
    );
  });
}
