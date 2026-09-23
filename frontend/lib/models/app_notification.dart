import 'user_role.dart';

enum NotificationKind { request, status, returnUpdate, review, system }

class AppNotification {
  final String id;
  final UserRole audience;
  final String title;
  final String message;
  final NotificationKind kind;
  final DateTime createdAt;
  final String? relatedRequestId;
  bool isRead;
  bool isDeleted;
  final bool isRemote;
  final String userId;

  AppNotification({
    required this.id,
    required this.audience,
    required this.title,
    required this.message,
    required this.kind,
    required this.createdAt,
    this.relatedRequestId,
    this.isRead = false,
    this.isDeleted = false,
    this.isRemote = false,
    this.userId = '',
  });

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
    UserRole audience,
  ) => AppNotification(
    id: json['id'].toString(),
    audience: audience,
    title: json['title'].toString(),
    message: json['message'].toString(),
    kind: json['kind'] == 'return_update'
        ? NotificationKind.returnUpdate
        : NotificationKind.values.byName(json['kind'].toString()),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    relatedRequestId: json['related_request_id']?.toString(),
    isRead: json['is_read'] as bool? ?? false,
    isDeleted: json['is_deleted'] as bool? ?? false,
    isRemote: true,
    userId: json['user_id'].toString(),
  );
}
