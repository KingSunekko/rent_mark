import 'package:flutter/foundation.dart';

import '../models/owner_listing.dart';
import '../models/rental_request.dart';
import '../models/rental_review.dart';
import '../models/user_role.dart';
import '../services/admin_api_service.dart';

class AdminState extends ChangeNotifier {
  final AdminApiService _api;
  final Set<String> _suspendedEmails = {};
  String? _token;
  int _version = 0;
  bool isLoading = false;
  String? error;
  List<MockUser> users = [];
  List<OwnerListing> listings = [];
  List<RentalRequest> requests = [];
  List<RentalReview> reviews = [];
  Map<String, int> metrics = {};

  AdminState({AdminApiService? api}) : _api = api ?? AdminApiService();
  bool get usesBackend => _token != null;

  bool isSuspended(String email) => _suspendedEmails.contains(email);

  void configureSession(String? token, UserRole? role) {
    final next = role == UserRole.admin ? token : null;
    if (_token == next) return;
    _token = next;
    final version = ++_version;
    users = [];
    listings = [];
    requests = [];
    reviews = [];
    metrics = {};
    isLoading = next != null;
    error = null;
    notifyListeners();
    if (next != null) _load(next, version);
  }

  Future<void> _load(String token, int version) async {
    try {
      final value = await _api.dashboard(token);
      if (_token != token || _version != version) return;
      users = value.users;
      listings = value.listings;
      requests = value.requests;
      reviews = value.reviews;
      metrics = value.metrics;
      _suspendedEmails
        ..clear()
        ..addAll(value.suspendedEmails);
      error = null;
    } catch (_) {
      if (_token != token || _version != version) return;
      error = 'Admin records could not be loaded.';
    } finally {
      if (_token == token && _version == version) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reload() async {
    final token = _token;
    if (token == null || isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    await _load(token, _version);
  }

  Future<void> setUserSuspended(
    MockUser user,
    bool suspended,
    String reason,
  ) async {
    final token = _token;
    if (token == null) throw StateError('Authentication required.');
    await _api.moderateUser(token, user.id, suspended, reason);
    if (suspended) {
      _suspendedEmails.add(user.email);
    } else {
      _suspendedEmails.remove(user.email);
    }
    notifyListeners();
  }

  Future<void> setListingHidden(
    OwnerListing item,
    bool hidden,
    String reason,
  ) async {
    final token = _token;
    if (token == null) throw StateError('Authentication required.');
    await _api.moderateItem(token, item.id, hidden, reason);
    item.moderationStatus = hidden
        ? ListingModerationStatus.hidden
        : ListingModerationStatus.active;
    notifyListeners();
  }
}
