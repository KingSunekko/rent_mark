import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/rental_request.dart';
import 'package:rent_mark/models/rental_review.dart';
import 'package:rent_mark/services/review_api_service.dart';
import 'package:rent_mark/state/reviews_state.dart';

import 'test_fixtures.dart';

RentalReview remoteReview() => RentalReview.fromJson({
  'id': '11111111-1111-4111-8111-111111111111',
  'rental_request_id': '22222222-2222-4222-8222-222222222222',
  'item_id': '33333333-3333-4333-8333-333333333333',
  'renter_id': '44444444-4444-4444-8444-444444444444',
  'owner_id': '55555555-5555-4555-8555-555555555555',
  'renter_name': 'Renter',
  'owner_name': 'Owner',
  'item_name': 'Camera',
  'rating': 5,
  'comment': 'Excellent.',
  'created_at': '2026-09-08T10:00:00Z',
});

RentalRequest completedRequest() => RentalRequest(
  id: '22222222-2222-4222-8222-222222222222',
  item: testRentalItem,
  renterName: 'Renter',
  renterId: '44444444-4444-4444-8444-444444444444',
  ownerId: '55555555-5555-4555-8555-555555555555',
  startDate: DateTime(2026, 9, 1),
  endDate: DateTime(2026, 9, 2),
  message: '',
  status: RentalRequestStatus.completed,
  requestedAt: DateTime(2026, 8, 30),
  isRemote: true,
);

class FakeReviewApi extends ReviewApiService {
  final loading = Completer<List<RentalReview>>();
  RentalReview? saved;

  @override
  Future<List<RentalReview>> list(String token) => loading.future;

  @override
  Future<RentalReview> create(
    String token, {
    required String rentalRequestId,
    required int rating,
    required String comment,
  }) async => saved ?? remoteReview();
}

void main() {
  test('review model reads authoritative backend fields', () {
    final review = remoteReview();
    expect(review.isRemote, isTrue);
    expect(review.rating, 5);
    expect(review.ownerId, isNotEmpty);
  });

  test('completed backend rental creates one remote review', () async {
    final api = FakeReviewApi()..saved = remoteReview();
    final state = ReviewsState(api: api);
    state.configureSession('token', 'renter');
    api.loading.complete([]);
    await Future<void>.delayed(Duration.zero);

    final first = await state.submit(
      request: completedRequest(),
      rating: 5,
      comment: 'Excellent.',
    );
    final second = await state.submit(
      request: completedRequest(),
      rating: 4,
      comment: 'Again',
    );

    expect(first, isNotNull);
    expect(second, isNull);
    expect(state.reviews, hasLength(1));
  });

  test('late review loads cannot leak after logout', () async {
    final api = FakeReviewApi();
    final state = ReviewsState(api: api);
    state.configureSession('token', 'renter');
    state.configureSession(null, null);
    api.loading.complete([remoteReview()]);
    await Future<void>.delayed(Duration.zero);
    expect(state.reviews.where((review) => review.isRemote), isEmpty);
  });
}
