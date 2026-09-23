import '../models/rental_review.dart';
import 'item_api_service.dart';

class ReviewApiService {
  final ItemApiService _transport;

  ReviewApiService({ItemApiService? transport})
    : _transport = transport ?? ItemApiService();

  Future<List<RentalReview>> list(String token) async {
    final reviews = <String, RentalReview>{};
    for (var offset = 0; ; offset += 50) {
      final data = await _transport.requestJson(
        'GET',
        '/api/v1/reviews?limit=50&offset=$offset',
        token,
      ) as List<dynamic>;
      for (final value in data) {
        final review = RentalReview.fromJson(value as Map<String, dynamic>);
        reviews[review.id] = review;
      }
      if (data.length < 50) return reviews.values.toList();
    }
  }

  Future<RentalReview> create(
    String token, {
    required String rentalRequestId,
    required int rating,
    required String comment,
  }) async {
    final data = await _transport.requestJson(
      'POST',
      '/api/v1/reviews',
      token,
      body: {
        'rental_request_id': rentalRequestId,
        'rating': rating,
        'comment': comment,
      },
    );
    return RentalReview.fromJson(data as Map<String, dynamic>);
  }
}
