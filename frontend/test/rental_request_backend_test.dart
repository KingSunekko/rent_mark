import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/rental_request.dart';
import 'package:rent_mark/services/item_api_service.dart';
import 'package:rent_mark/services/rental_request_api_service.dart';
import 'package:rent_mark/state/rental_requests_state.dart';
import 'package:rent_mark/services/auth_api_service.dart';

Map<String, dynamic> record([String id = 'saved']) => {
  'id': id,
  'renter_id': 'renter',
  'owner_id': 'owner',
  'renter_name': 'Renter',
  'start_date': '2026-09-10',
  'end_date': '2026-09-12',
  'total_centavos': 25245,
  'message': 'Hello',
  'pickup_method': 'Community meetup',
  'status': 'pending',
  'requested_at': '2026-09-07T10:00:00Z',
  'item_snapshot': {
    'id': '11111111-1111-4111-8111-111111111111',
    'owner_id': 'owner',
    'owner_name': 'Owner',
    'name': 'Camera',
    'description': 'A camera for events.',
    'category': 'electronics',
    'condition': 'Good',
    'price_per_day': 99,
    'discount_percent': 15,
    'availability': 'available',
    'community': 'Davao',
    'moderation_status': 'active',
  },
};

class Transport extends ItemApiService {
  final paths = <String>[];
  Map<String, Object>? submitted;
  @override
  Future<dynamic> requestJson(
    String method,
    String path,
    String token, {
    Map<String, Object>? body,
  }) async {
    paths.add(path);
    if (method == 'POST') {
      submitted = body;
      return record();
    }
    if (path.endsWith('offset=0')) {
      return List.generate(50, (i) => record('request-$i'));
    }
    return [record('last')];
  }
}

class FakeApi extends RentalRequestApiService {
  final loading = Completer<List<RentalRequest>>();
  final creating = Completer<RentalRequest>();
  final keys = <String>[];
  RentalRequest? transitioned;
  @override
  Future<List<RentalRequest>> list(String token) => loading.future;
  @override
  Future<RentalRequest> create(
    String token,
    RentalRequest draft,
    String submissionId,
  ) {
    keys.add(submissionId);
    return creating.future;
  }

  @override
  Future<RentalRequest> transition(
    String token,
    String requestId,
    RentalRequestStatus status, {
    String rejectionReason = '',
  }) async {
    final updated = RentalRequest.fromJson({
      ...record(requestId),
      'status': status == RentalRequestStatus.returnRequested
          ? 'return_requested'
          : status.name,
      'rejection_reason': rejectionReason,
      if (status == RentalRequestStatus.approved ||
          status == RentalRequestStatus.active ||
          status == RentalRequestStatus.returnRequested ||
          status == RentalRequestStatus.completed)
        'approved_at': '2026-09-08T12:00:00Z',
      if (status == RentalRequestStatus.active ||
          status == RentalRequestStatus.returnRequested ||
          status == RentalRequestStatus.completed)
        'started_at': '2026-09-08T13:00:00Z',
      if (status == RentalRequestStatus.returnRequested ||
          status == RentalRequestStatus.completed)
        'return_requested_at': '2026-09-08T14:00:00Z',
      if (status == RentalRequestStatus.completed)
        'completed_at': '2026-09-08T15:00:00Z',
    });
    transitioned = updated;
    return updated;
  }
}

void main() {
  test(
    'remote model displays authoritative server total and immutable quote',
    () {
      final request = RentalRequest.fromJson(record());
      expect(request.isRemote, isTrue);
      expect(request.estimatedTotalLabel, '₱252.45');
      expect(request.item.priceLabel, '₱84.15 / day');
      expect(request.durationDays, 3);
    },
  );

  test('submission excludes client ownership, prices, and status', () async {
    final transport = Transport();
    final api = RentalRequestApiService(transport: transport);
    final key = RentalRequestApiService.newSubmissionId();
    await api.create('token', RentalRequest.fromJson(record()), key);
    expect(transport.submitted!.keys.toSet(), {
      'client_request_id',
      'item_id',
      'start_date',
      'end_date',
      'message',
      'pickup_method',
    });
    expect(transport.submitted!['client_request_id'], key);
    expect(transport.submitted!['start_date'], '2026-09-10');
    expect(
      key,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('request list fetches all pages', () async {
    final transport = Transport();
    final rows = await RentalRequestApiService(transport: transport)
        .list('token');
    expect(rows.length, 51);
    expect(transport.paths.last, endsWith('offset=50'));
  });

  test('late request loads cannot leak into another account', () async {
    final api = FakeApi();
    final state = RentalRequestsState(api: api);
    state.configureSession('token', 'renter');
    state.configureSession(null, null);
    api.loading.complete([RentalRequest.fromJson(record())]);
    await Future<void>.delayed(Duration.zero);
    expect(state.requests.any((r) => r.isRemote), isFalse);
    state.dispose();
  });

  test('backend submission failure does not create a local request', () async {
    final api = FakeApi();
    final state = RentalRequestsState(api: api);
    state.configureSession('token', 'renter');
    api.loading.complete([]);
    final saving = state.submitRequest(
      RentalRequest.fromJson(record()),
      'retry-key',
    );
    api.creating.completeError(const ApiException('offline'));
    await expectLater(saving, throwsA(isA<ApiException>()));
    expect(state.requests, isEmpty);
    state.dispose();
  });

  test('successful replay deduplicates requests and remote transitions use backend', () async {
    final api = FakeApi();
    final state = RentalRequestsState(api: api);
    state.configureSession('token', 'renter');
    api.loading.complete([]);
    final request = RentalRequest.fromJson(record());
    api.creating.complete(request);
    await state.submitRequest(request, 'retry-key');
    await state.submitRequest(request, 'retry-key');
    expect(api.keys, ['retry-key', 'retry-key']);
    expect(state.requests.length, 1);
    await state.approve(request);
    await state.startRental(request);
    await state.requestReturn(request);
    await state.confirmReturn(request);
    expect(request.status, RentalRequestStatus.completed);
    expect(request.approvedAt, isNotNull);
    expect(request.startedAt, isNotNull);
    expect(request.returnRequestedAt, isNotNull);
    expect(request.completedAt, isNotNull);
    state.dispose();
  });
}
