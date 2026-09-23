import '../models/app_notification.dart';
import '../models/user_role.dart';
import 'item_api_service.dart';

class NotificationApiService {
  final ItemApiService _transport;
  NotificationApiService({ItemApiService? transport})
    : _transport = transport ?? ItemApiService();

  Future<List<AppNotification>> list(String token, UserRole role) async {
    final values = <String, AppNotification>{};
    for (var offset = 0; ; offset += 50) {
      final data = await _transport.requestJson(
        'GET',
        '/api/v1/notifications?limit=50&offset=$offset',
        token,
      ) as List<dynamic>;
      for (final row in data) {
        final item = AppNotification.fromJson(
          row as Map<String, dynamic>,
          role,
        );
        values[item.id] = item;
      }
      if (data.length < 50) return values.values.toList();
    }
  }

  Future<void> update(
    String token,
    String id, {
    bool? isRead,
    bool? isDeleted,
  }) async {
    await _transport.requestJson(
      'PATCH',
      '/api/v1/notifications/$id',
      token,
      body: {'is_read': ?isRead, 'is_deleted': ?isDeleted},
    );
  }

  Future<void> updateReadBatch(
    String token,
    List<String> ids,
    bool isRead,
  ) async {
    for (var start = 0; start < ids.length; start += 100) {
      final end = (start + 100).clamp(0, ids.length);
      await _transport.requestJson(
        'PATCH',
        '/api/v1/notifications',
        token,
        body: {'notification_ids': ids.sublist(start, end), 'is_read': isRead},
      );
    }
  }
}
