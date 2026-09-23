import 'package:flutter/foundation.dart';

import '../models/owner_listing.dart';
import '../models/rental_item.dart';
import '../services/api_config.dart';
import '../services/item_api_service.dart';
import '../services/auth_api_service.dart';

class OwnerListingsStore extends ChangeNotifier {
  OwnerListingsStore._() : _api = ItemApiService(), _apiEnabled = null;
  @visibleForTesting
  OwnerListingsStore.forTesting(ItemApiService api)
    : _api = api,
      _apiEnabled = true;
  static final OwnerListingsStore instance = OwnerListingsStore._();
  final ItemApiService _api;
  final bool? _apiEnabled;
  bool get _remoteEnabled => _apiEnabled ?? ApiConfig.enabled;
  int _session = 0;
  int _ownerLoad = 0;
  int _publicLoad = 0;
  List<OwnerListing> _publicItems = [];
  bool _publicLoaded = false;
  String? _loadedOwnerId;
  bool isLoading = false;
  String? error;

  final List<OwnerListing> _items = [];

  List<OwnerListing> get items => List.unmodifiable(_items);
  List<OwnerListing> get visibleItems => List.unmodifiable(
    _items.where(
      (item) => item.moderationStatus == ListingModerationStatus.active,
    ),
  );
  List<OwnerListing> get discoveryItems =>
      List.unmodifiable(_publicLoaded ? _publicItems : visibleItems);

  Future<void> loadPublic(String? token) async {
    if (!_remoteEnabled || token == null) return;
    final session = _session;
    final request = ++_publicLoad;
    bool current() => session == _session && request == _publicLoad;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final items = await _api.listPublic(token);
      if (!current()) return;
      _publicItems = items;
      _publicLoaded = true;
    } catch (exception) {
      if (!current()) return;
      _publicLoaded = false;
      error = exception.toString();
    } finally {
      if (current()) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadOwner(String? token, {String? ownerId}) async {
    if (!_remoteEnabled || token == null) return;
    if (_loadedOwnerId != ownerId) {
      resetSession();
      _items.clear();
      _loadedOwnerId = ownerId;
    }
    final session = _session;
    final request = ++_ownerLoad;
    bool current() => session == _session && request == _ownerLoad;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final items = await _api.listOwner(token);
      if (!current()) return;
      _items
        ..clear()
        ..addAll(items);
    } catch (exception) {
      if (!current()) return;
      error = exception.toString();
    } finally {
      if (current()) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<OwnerListing> saveRemote(OwnerListing item, String? token) async {
    if (!_remoteEnabled || token == null) {
      if (_items.any((existing) => existing.id == item.id)) {
        update(item);
      } else {
        add(item);
      }
      return item;
    }

    final session = _session;
    final uploadedPaths = <String>[];
    final imagePaths = <String>[];
    void checkSession() {
      if (session != _session) {
        throw const ApiException(
          'Your account session changed. Please try again.',
        );
      }
    }

    try {
      for (var index = 0; index < item.galleryUrls.length; index++) {
        checkSession();
        final path = item.galleryUrls[index];
        if (path.startsWith('http://') || path.startsWith('https://')) {
          if (index < item.storagePaths.length) {
            imagePaths.add(item.storagePaths[index]);
          }
        } else {
          final uploaded = await _api.uploadImage(token, path);
          uploadedPaths.add(uploaded.path);
          imagePaths.add(uploaded.path);
        }
      }
      checkSession();
      final saved = item.id.startsWith('owner-local-')
          ? await _api.create(token, item, imagePaths)
          : await _api.update(token, item, imagePaths);
      if (session == _session) {
        update(saved);
        if (!_items.any((existing) => existing.id == saved.id)) add(saved);
      }
      return saved;
    } catch (_) {
      // Only paths uploaded by this attempt are candidates. The backend also
      // checks references in case a timed-out save actually committed.
      try {
        await _api.cleanupImages(token, uploadedPaths);
      } catch (_) {
        debugPrint('Unused listing photos could not be cleaned up.');
      }
      rethrow;
    }
  }

  Future<void> removeRemote(String id, String? token) async {
    final session = _session;
    if (_remoteEnabled && token != null && !id.startsWith('owner-local-')) {
      await _api.delete(token, id);
    }
    if (session == _session) remove(id);
  }

  Future<void> toggleAvailabilityRemote(String id, String? token) async {
    final session = _session;
    final item = _items.firstWhere((value) => value.id == id);
    final previous = item.availability;
    item.availability = previous == AvailabilityStatus.unavailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.unavailable;
    notifyListeners();
    if (_remoteEnabled && token != null && !id.startsWith('owner-local-')) {
      try {
        final saved = await _api.update(token, item, item.storagePaths);
        if (session == _session) update(saved);
      } catch (_) {
        if (session == _session) {
          item.availability = previous;
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  void resetSession() {
    _session++;
    _ownerLoad++;
    _publicLoad++;
    _publicItems = [];
    _publicLoaded = false;
    _loadedOwnerId = null;
    error = null;
    isLoading = false;
    _items.clear();
    notifyListeners();
  }

  void add(OwnerListing item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void update(OwnerListing updated) {
    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    _items[index] = updated;
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void toggleAvailability(String id) {
    final item = _items.firstWhere((item) => item.id == id);
    item.availability = item.availability == AvailabilityStatus.unavailable
        ? AvailabilityStatus.available
        : AvailabilityStatus.unavailable;
    notifyListeners();
  }

  void toggleModeration(String id) {
    final item = _items.firstWhere((item) => item.id == id);
    item.moderationStatus =
        item.moderationStatus == ListingModerationStatus.hidden
        ? ListingModerationStatus.active
        : ListingModerationStatus.hidden;
    notifyListeners();
  }
}
