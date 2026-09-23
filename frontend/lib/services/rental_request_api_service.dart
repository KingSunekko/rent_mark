import 'dart:math';

import '../models/rental_request.dart';
import 'item_api_service.dart';

class RentalRequestApiService {
  final ItemApiService _transport;
  RentalRequestApiService({ItemApiService? transport})
    : _transport = transport ?? ItemApiService();

  static String newSubmissionId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<RentalRequest> create(
    String token,
    RentalRequest draft,
    String submissionId,
  ) async {
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final data = await _transport.requestJson(
      'POST',
      '/api/v1/rental-requests',
      token,
      body: {
        'client_request_id': submissionId,
        'item_id': draft.item.id,
        'start_date': date(draft.startDate),
        'end_date': date(draft.endDate),
        'message': draft.message,
        'pickup_method': draft.pickupMethod,
      },
    );
    return RentalRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RentalRequest>> list(String token) async {
    final requests = <String, RentalRequest>{};
    for (var offset = 0; ; offset += 50) {
      final data = await _transport.requestJson(
        'GET',
        '/api/v1/rental-requests?limit=50&offset=$offset',
        token,
      ) as List<dynamic>;
      for (final row in data) {
        final request = RentalRequest.fromJson(row as Map<String, dynamic>);
        requests[request.id] = request;
      }
      if (data.length < 50) return requests.values.toList();
    }
  }

  Future<RentalRequest> transition(
    String token,
    String requestId,
    RentalRequestStatus status, {
    String rejectionReason = '',
  }) async {
    final apiStatus = status == RentalRequestStatus.returnRequested
        ? 'return_requested'
        : status.name;
    final data = await _transport.requestJson(
      'PATCH',
      '/api/v1/rental-requests/$requestId/status',
      token,
      body: {'status': apiStatus, 'rejection_reason': rejectionReason},
    );
    return RentalRequest.fromJson(data as Map<String, dynamic>);
  }
}
