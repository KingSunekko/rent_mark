import 'package:flutter/foundation.dart';

import '../models/rental_request.dart';
import '../services/rental_request_api_service.dart';

/// Shared local request state used by both renter and owner flows.
/// Seeded demo requests remain available alongside newly submitted requests;
/// all data resets when the app restarts.
class RentalRequestsState extends ChangeNotifier {
  final RentalRequestApiService _api;
  final List<RentalRequest> _requests = [];
  String? _accessToken;
  String? _accountId;
  int _sessionVersion = 0;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  RentalRequestsState({RentalRequestApiService? api})
    : _api = api ?? RentalRequestApiService();

  List<RentalRequest> get requests => List.unmodifiable(_requests.reversed);
  bool get usesBackend => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Switches between the local demo data and the authenticated backend data.
  void configureSession(String? accessToken, String? accountId) {
    if (_accessToken == accessToken && _accountId == accountId) return;
    _accessToken = accessToken;
    _accountId = accountId;
    final version = ++_sessionVersion;
    _isLoading = accessToken != null;
    _error = null;

    _requests.clear();
    _notifyIfActive();

    if (accessToken != null) _loadRemoteRequests(accessToken, version);
  }

  Future<void> _loadRemoteRequests(String token, int version) async {
    try {
      final loaded = await _api.list(token);
      if (version != _sessionVersion || token != _accessToken) return;
      _requests
        ..clear()
        ..addAll(loaded);
      _error = null;
    } catch (exception) {
      if (version != _sessionVersion || token != _accessToken) return;
      _error = 'Could not load rental requests. Please try again.';
      debugPrint('Rental request sync failed: $exception');
    } finally {
      if (version == _sessionVersion && token == _accessToken) {
        _isLoading = false;
        _notifyIfActive();
      }
    }
  }

  Future<void> reload() async {
    final token = _accessToken;
    if (token == null || _isLoading) return;
    final version = _sessionVersion;
    _isLoading = true;
    _error = null;
    _notifyIfActive();
    await _loadRemoteRequests(token, version);
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }

  Future<RentalRequest> submitRequest(
    RentalRequest draft,
    String submissionId,
  ) async {
    final token = _accessToken;
    if (token == null) {
      return submit(build: (_) => draft);
    }

    final created = await _api.create(token, draft, submissionId);
    if (token != _accessToken) return created;
    final existing = _requests.indexWhere(
      (request) => request.id == created.id,
    );
    if (existing < 0) {
      _requests.add(created);
    } else {
      _requests[existing] = created;
    }
    notifyListeners();
    return created;
  }

  RentalRequest submit({required RentalRequest Function(String id) build}) {
    final id = 'REQ-${(_requests.length + 1).toString().padLeft(3, '0')}';
    final request = build(id);
    _requests.add(request);
    notifyListeners();
    return request;
  }

  Future<void> approve(RentalRequest request) async {
    if (request.isRemote) {
      await _transitionRemote(request, RentalRequestStatus.approved);
      return;
    }
    if (request.status != RentalRequestStatus.pending) return;
    request.status = RentalRequestStatus.approved;
    request.approvedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> reject(RentalRequest request, {String reason = ''}) async {
    if (request.isRemote) {
      await _transitionRemote(
        request,
        RentalRequestStatus.rejected,
        rejectionReason: reason,
      );
      return;
    }
    if (request.status != RentalRequestStatus.pending) return;
    request.status = RentalRequestStatus.rejected;
    request.rejectionReason = reason;
    notifyListeners();
  }

  Future<void> startRental(RentalRequest request) async {
    if (request.isRemote) {
      await _transitionRemote(request, RentalRequestStatus.active);
      return;
    }
    if (request.status != RentalRequestStatus.approved) return;
    request.status = RentalRequestStatus.active;
    request.startedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> requestReturn(RentalRequest request) async {
    if (request.isRemote) {
      await _transitionRemote(request, RentalRequestStatus.returnRequested);
      return;
    }
    if (request.status != RentalRequestStatus.active) return;
    request.status = RentalRequestStatus.returnRequested;
    request.returnRequestedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> confirmReturn(RentalRequest request) async {
    if (request.isRemote) {
      await _transitionRemote(request, RentalRequestStatus.completed);
      return;
    }
    if (request.status != RentalRequestStatus.returnRequested) return;
    request.status = RentalRequestStatus.completed;
    request.completedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> _transitionRemote(
    RentalRequest request,
    RentalRequestStatus status, {
    String rejectionReason = '',
  }) async {
    final token = _accessToken;
    if (token == null) return;
    final updated = await _api.transition(
      token,
      request.id,
      status,
      rejectionReason: rejectionReason,
    );
    if (token != _accessToken) return;
    request.status = updated.status;
    request.rejectionReason = updated.rejectionReason;
    request.approvedAt = updated.approvedAt;
    request.rejectedAt = updated.rejectedAt;
    request.startedAt = updated.startedAt;
    request.returnRequestedAt = updated.returnRequestedAt;
    request.completedAt = updated.completedAt;
    _notifyIfActive();
  }

  bool hasDateConflict({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _requests.any((request) {
      if (request.item.id != itemId) return false;
      if (request.status != RentalRequestStatus.approved &&
          request.status != RentalRequestStatus.active &&
          request.status != RentalRequestStatus.returnRequested) {
        return false;
      }
      return !endDate.isBefore(request.startDate) &&
          !startDate.isAfter(request.endDate);
    });
  }
}
