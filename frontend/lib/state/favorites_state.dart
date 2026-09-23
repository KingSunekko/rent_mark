import 'package:flutter/foundation.dart';

import '../models/rental_item.dart';

class FavoritesState extends ChangeNotifier {
  final Map<String, RentalItem> _items = {};
  final Map<String, RentalItem> _recentlyViewed = {};

  List<RentalItem> get items => List.unmodifiable(_items.values);
  List<RentalItem> get recentlyViewed =>
      List.unmodifiable(_recentlyViewed.values.toList().reversed);

  bool contains(String itemId) => _items.containsKey(itemId);

  void toggle(RentalItem item) {
    if (_items.containsKey(item.id)) {
      _items.remove(item.id);
    } else {
      _items[item.id] = item;
    }
    notifyListeners();
  }

  void recordViewed(RentalItem item) {
    _recentlyViewed.remove(item.id);
    _recentlyViewed[item.id] = item;
    while (_recentlyViewed.length > 10) {
      _recentlyViewed.remove(_recentlyViewed.keys.first);
    }
    notifyListeners();
  }

  void clearRecentlyViewed() {
    _recentlyViewed.clear();
    notifyListeners();
  }
}
