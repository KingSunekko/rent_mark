import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../theme/app_theme.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  IconData get _icon {
    switch (notification.kind) {
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

  String get _type {
    switch (notification.kind) {
      case NotificationKind.request:
        return 'Rental request';
      case NotificationKind.status:
        return 'Status update';
      case NotificationKind.returnUpdate:
        return 'Return update';
      case NotificationKind.review:
        return 'Review';
      case NotificationKind.system:
        return 'System';
    }
  }

  String get _createdAt {
    final date = notification.createdAt;
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(_icon, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(label: 'Type', value: _type),
                  const SizedBox(height: AppSpacing.sm),
                  _DetailRow(label: 'Received', value: _createdAt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
