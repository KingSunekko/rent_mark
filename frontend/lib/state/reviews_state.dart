import 'package:flutter/foundation.dart';

import '../models/rental_request.dart';
import '../models/rental_review.dart';
import '../services/review_api_service.dart';

class ReviewsState extends ChangeNotifier {
  final ReviewApiService _api;
  final List<RentalReview> _reviews = [];
  String? _accessToken;
  String? _accountId;
  int _sessionVersion = 0;
  bool isLoading = false;
  String? error;

  ReviewsState({ReviewApiService? api}) : _api = api ?? ReviewApiService();

  List<RentalReview> get reviews => List.unmodifiable(_reviews.reversed);

  bool hasReviewed(String rentalId) =>
      _reviews.any((review) => review.rentalId == rentalId);

  List<RentalReview> forOwner(String ownerName) => _reviews
      .where((review) => review.ownerName == ownerName)
      .toList()
      .reversed
      .toList();

  List<RentalReview> byRenter(String renterName) => _reviews
      .where((review) => review.renterName == renterName)
      .toList()
      .reversed
      .toList();

  List<RentalReview> forOwnerId(String ownerId, {String fallbackName = ''}) =>
      _reviews
          .where(
            (review) =>
                review.ownerId == ownerId ||
                (review.ownerId.isEmpty && review.ownerName == fallbackName),
          )
          .toList()
          .reversed
          .toList();

  List<RentalReview> byRenterId(String renterId, {String fallbackName = ''}) =>
      _reviews
          .where(
            (review) =>
                review.renterId == renterId ||
                (review.renterId.isEmpty && review.renterName == fallbackName),
          )
          .toList()
          .reversed
          .toList();

  List<RentalReview> forItem(String itemId) =>
      _reviews.where((review) => review.itemId == itemId).toList();

  double averageForOwner(String ownerName) {
    final matches = forOwner(ownerName);
    if (matches.isEmpty) return 0;
    return matches.fold<int>(0, (sum, review) => sum + review.rating) /
        matches.length;
  }

  void configureSession(String? accessToken, String? accountId) {
    if (_accessToken == accessToken && _accountId == accountId) return;
    _accessToken = accessToken;
    _accountId = accountId;
    final version = ++_sessionVersion;
    _reviews.removeWhere((review) => review.isRemote);
    isLoading = accessToken != null;
    error = null;
    notifyListeners();
    if (accessToken != null) _load(accessToken, version);
  }

  Future<void> _load(String token, int version) async {
    try {
      final loaded = await _api.list(token);
      if (version != _sessionVersion || token != _accessToken) return;
      _reviews
        ..removeWhere((review) => review.isRemote)
        ..addAll(loaded);
      error = null;
    } catch (_) {
      if (version != _sessionVersion || token != _accessToken) return;
      error = 'Reviews could not be loaded. Please try again.';
    } finally {
      if (version == _sessionVersion && token == _accessToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reload() async {
    final token = _accessToken;
    if (token == null || isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    await _load(token, _sessionVersion);
  }

  Future<RentalReview?> submit({
    required RentalRequest request,
    required int rating,
    required String comment,
  }) async {
    if (request.status != RentalRequestStatus.completed ||
        hasReviewed(request.id)) {
      return null;
    }

    final token = _accessToken;
    final review = token == null
        ? RentalReview(
            id: 'REV-${(_reviews.length + 1).toString().padLeft(3, '0')}',
            rentalId: request.id,
            itemId: request.item.id,
            itemName: request.item.name,
            renterName: request.renterName,
            ownerName: request.item.ownerName,
            rating: rating.clamp(1, 5),
            comment: comment.trim(),
            createdAt: DateTime.now(),
          )
        : await _api.create(
            token,
            rentalRequestId: request.id,
            rating: rating,
            comment: comment.trim(),
          );
    if (token != _accessToken || hasReviewed(review.rentalId)) return review;
    _reviews.add(review);
    notifyListeners();
    return review;
  }
}
