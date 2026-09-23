import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/user_role.dart';
import '../services/notification_api_service.dart';

class NotificationsState extends ChangeNotifier {
  final NotificationApiService _api;
  final List<AppNotification> _notifications = [];
  String? _accessToken;
  String? _accountId;
  UserRole? _role;
  int _sessionVersion = 0;
  bool isLoading = false;
  String? error;

  NotificationsState({NotificationApiService? api})
    : _api = api ?? NotificationApiService();

  List<AppNotification> forRole(UserRole role) => _notifications
      .where((notification) => notification.audience == role)
      .toList()
      .reversed
      .toList();

  int unreadFor(UserRole role) => forRole(role).where((n) => !n.isRead).length;

  void configureSession(
    String? accessToken,
    String? accountId,
    UserRole? role,
  ) {
    if (_accessToken == accessToken &&
        _accountId == accountId &&
        _role == role) {
      return;
    }
    _accessToken = accessToken;
    _accountId = accountId;
    _role = role;
    final version = ++_sessionVersion;
    _notifications.removeWhere((item) => item.isRemote);
    isLoading = accessToken != null && role != null;
    error = null;
    notifyListeners();
    if (accessToken != null && role != null) _load(accessToken, role, version);
  }

  Future<void> _load(String token, UserRole role, int version) async {
    try {
      final loaded = await _api.list(token, role);
      if (version != _sessionVersion || token != _accessToken) return;
      _notifications
        ..removeWhere((item) => item.isRemote)
        ..addAll(loaded);
      error = null;
    } catch (_) {
      if (version != _sessionVersion || token != _accessToken) return;
      error = 'Notifications could not be loaded. Please try again.';
    } finally {
      if (version == _sessionVersion && token == _accessToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> reload() async {
    final token = _accessToken;
    final role = _role;
    if (token == null || role == null || isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    await _load(token, role, _sessionVersion);
  }

  void add({
    required UserRole audience,
    required String title,
    required String message,
    required NotificationKind kind,
    String? relatedRequestId,
  }) {
    _notifications.add(
      AppNotification(
        id: 'NOT-${_notifications.length + 1}',
        audience: audience,
        title: title,
        message: message,
        kind: kind,
        createdAt: DateTime.now(),
        relatedRequestId: relatedRequestId,
      ),
    );
    notifyListeners();
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    notification.isRead = true;
    notifyListeners();
    if (notification.isRemote && _accessToken != null) {
      try {
        await _api.update(_accessToken!, notification.id, isRead: true);
      } catch (_) {
        notification.isRead = false;
        error = 'Notification could not be updated.';
        notifyListeners();
      }
    }
  }

  Future<void> markAllRead(UserRole role) async {
    final changed = forRole(role).where((item) => !item.isRead).toList();
    for (final notification in _notifications) {
      if (notification.audience == role) notification.isRead = true;
    }
    notifyListeners();
    final remoteIds = changed
        .where((item) => item.isRemote)
        .map((item) => item.id)
        .toList();
    if (remoteIds.isNotEmpty && _accessToken != null) {
      try {
        await _api.updateReadBatch(_accessToken!, remoteIds, true);
      } catch (_) {
        for (final item in changed) {
          item.isRead = false;
        }
        error = 'Notifications could not be updated.';
        notifyListeners();
      }
    }
  }

  Future<void> markUnread(Iterable<AppNotification> notifications) async {
    final changed = notifications.toList();
    for (final notification in changed) {
      notification.isRead = false;
    }
    notifyListeners();
    final remoteIds = changed
        .where((item) => item.isRemote)
        .map((item) => item.id)
        .toList();
    if (remoteIds.isNotEmpty && _accessToken != null) {
      try {
        await _api.updateReadBatch(_accessToken!, remoteIds, false);
      } catch (_) {
        for (final item in changed) {
          item.isRead = true;
        }
        error = 'Notifications could not be updated.';
        notifyListeners();
      }
    }
  }

  Future<void> remove(AppNotification notification) async {
    _notifications.remove(notification);
    notifyListeners();
    if (notification.isRemote && _accessToken != null) {
      try {
        await _api.update(_accessToken!, notification.id, isDeleted: true);
      } catch (_) {
        _notifications.add(notification);
        error = 'Notification could not be dismissed.';
        notifyListeners();
      }
    }
  }

  Future<void> restore(AppNotification notification) async {
    if (_notifications.contains(notification)) return;
    _notifications.add(notification);
    notifyListeners();
    if (notification.isRemote && _accessToken != null) {
      try {
        await _api.update(_accessToken!, notification.id, isDeleted: false);
      } catch (_) {
        _notifications.remove(notification);
        error = 'Notification could not be restored.';
        notifyListeners();
      }
    }
  }
}
