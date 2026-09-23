import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../models/rental_request.dart';
import '../models/user_role.dart';
import '../state/notifications_state.dart';
import '../state/rental_requests_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_pill.dart';
import 'notification_details_screen.dart';
import 'owner_request_details_screen.dart';
import 'rental_request_details_screen.dart';

enum _Filter { all, requests, rentals, returns, reviews }

class NotificationsScreen extends StatefulWidget {
  final UserRole role;
  final VoidCallback? onBack;
  const NotificationsScreen({super.key, required this.role, this.onBack});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Filter filter = _Filter.all;

  bool _matches(AppNotification item) {
    switch (filter) {
      case _Filter.all:
        return true;
      case _Filter.requests:
        return item.kind == NotificationKind.request;
      case _Filter.rentals:
        return item.kind == NotificationKind.status;
      case _Filter.returns:
        return item.kind == NotificationKind.returnUpdate;
      case _Filter.reviews:
        return item.kind == NotificationKind.review;
    }
  }

  IconData _icon(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.request:
        return Icons.receipt_long_rounded;
      case NotificationKind.status:
        return Icons.sync_alt_rounded;
      case NotificationKind.returnUpdate:
        return Icons.keyboard_return_rounded;
      case NotificationKind.review:
        return Icons.star_rounded;
      case NotificationKind.system:
        return Icons.info_outline_rounded;
    }
  }

  Color _color(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.request:
        return AppColors.primary;
      case NotificationKind.status:
        return AppColors.success;
      case NotificationKind.returnUpdate:
        return AppColors.purple;
      case NotificationKind.review:
        return AppColors.warning;
      case NotificationKind.system:
        return AppColors.textSecondary;
    }
  }

  String _relative(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${time.month}/${time.day}/${time.year}';
  }

  String _group(DateTime time) {
    final now = DateTime.now();
    final date = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }

  RentalRequest? _relatedRequest(String? id) {
    if (id == null) return null;
    for (final request in context.read<RentalRequestsState>().requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  void _open(AppNotification item) {
    context.read<NotificationsState>().markRead(item);
    final request = _relatedRequest(item.relatedRequestId);
    final Widget page = request == null
        ? NotificationDetailsScreen(notification: item)
        : widget.role == UserRole.owner
        ? OwnerRequestDetailsScreen(request: request)
        : RentalRequestDetailsScreen(request: request);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _markAll(List<AppNotification> all) {
    final unread = all.where((item) => !item.isRead).toList();
    context.read<NotificationsState>().markAllRead(widget.role);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () =>
              context.read<NotificationsState>().markUnread(unread),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsState>();
    final all = state.forRole(widget.role);
    final visible = all.where(_matches).toList();
    final grouped = <String, List<AppNotification>>{};
    for (final item in visible) {
      grouped.putIfAbsent(_group(item.createdAt), () => []).add(item);
    }
    final canBack = widget.onBack != null || Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  if (canBack)
                    IconButton(
                      onPressed:
                          widget.onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (all.any((item) => !item.isRead))
                    TextButton(
                      onPressed: () => _markAll(all),
                      child: const Text('MARK ALL READ'),
                    ),
                ],
              ),
            ),
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: state.reload,
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _chip('All', _Filter.all, all.length),
                  _chip(
                    'Requests',
                    _Filter.requests,
                    all
                        .where((item) => item.kind == NotificationKind.request)
                        .length,
                  ),
                  _chip(
                    'Rentals',
                    _Filter.rentals,
                    all
                        .where((item) => item.kind == NotificationKind.status)
                        .length,
                  ),
                  _chip(
                    'Returns',
                    _Filter.returns,
                    all
                        .where(
                          (item) => item.kind == NotificationKind.returnUpdate,
                        )
                        .length,
                  ),
                  _chip(
                    'Reviews',
                    _Filter.reviews,
                    all
                        .where((item) => item.kind == NotificationKind.review)
                        .length,
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No notifications here',
                        message:
                            'Updates matching this filter will appear here.',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ...entry.value.map(
                            (item) => _NotificationRow(
                              item: item,
                              icon: _icon(item.kind),
                              color: _color(item.kind),
                              time: _relative(item.createdAt),
                              tap: () => _open(item),
                              dismiss: () {
                                state.remove(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Notification removed.',
                                    ),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () => state.restore(item),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter value, int count) => FilterPill(
    label: label,
    count: count,
    selected: filter == value,
    onTap: () => setState(() => filter = value),
  );
}

class _NotificationRow extends StatelessWidget {
  final AppNotification item;
  final IconData icon;
  final Color color;
  final String time;
  final VoidCallback tap;
  final VoidCallback dismiss;
  const _NotificationRow({
    required this.item,
    required this.icon,
    required this.color,
    required this.time,
    required this.tap,
    required this.dismiss,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(item.id),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => dismiss(),
    background: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.surface : color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.isRead ? AppColors.border : color.withValues(alpha: .25),
        ),
      ),
      child: ListTile(
        onTap: tap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(time, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        trailing: item.isRead
            ? const Icon(Icons.chevron_right_rounded)
            : Icon(Icons.circle, size: 9, color: color),
      ),
    ),
  );
}
