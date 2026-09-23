String _normalizedArea(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool isItemInCommunity({
  required String userCommunity,
  required String itemCommunity,
  required String itemCity,
}) {
  final user = _normalizedArea(userCommunity);
  if (user.isEmpty) return false;

  for (final value in [itemCommunity, itemCity]) {
    final area = _normalizedArea(value);
    if (area.isEmpty) continue;
    if (area == user || user.endsWith(' $area') || area.endsWith(' $user')) {
      return true;
    }
  }
  return false;
}
