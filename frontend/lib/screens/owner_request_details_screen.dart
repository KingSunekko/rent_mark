import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import '../state/rental_requests_state.dart';
import '../state/notifications_state.dart';
import '../models/app_notification.dart';
import '../models/user_role.dart';
import '../widgets/item_image.dart';
import '../widgets/request_review_section.dart';
import '../widgets/request_status_badge.dart';
import '../widgets/rental_status_timeline.dart';

class OwnerRequestDetailsScreen extends StatefulWidget {
  final RentalRequest request;

  const OwnerRequestDetailsScreen({super.key, required this.request});

  @override
  State<OwnerRequestDetailsScreen> createState() =>
      _OwnerRequestDetailsScreenState();
}

class _OwnerRequestDetailsScreenState extends State<OwnerRequestDetailsScreen> {
  RentalRequest get request => widget.request;

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Rental Request?'),
        content: Text(
          '${request.item.name}\nRenter: ${request.renterName}\nDates: ${request.rentalPeriodLabel}\nTotal: ${request.estimatedTotalLabel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<RentalRequestsState>().approve(request);
      context.read<NotificationsState>().add(
        audience: UserRole.renter,
        title: 'Request approved',
        message: 'Your request for ${request.item.name} was approved.',
        kind: NotificationKind.status,
        relatedRequestId: request.id,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rental request approved.')));
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Rental Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.item.name}\nRenter: ${request.renterName}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                hintText: 'Item is unavailable during these dates.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<RentalRequestsState>().reject(
        request,
        reason: controller.text.trim(),
      );
      context.read<NotificationsState>().add(
        audience: UserRole.renter,
        title: 'Request rejected',
        message: 'Your request for ${request.item.name} was not approved.',
        kind: NotificationKind.status,
        relatedRequestId: request.id,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rental request rejected.')));
    }
    controller.dispose();
  }

  Future<void> _startRental() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Rental?'),
        content: Text(
          'Mark ${request.item.name} as handed over to ${request.renterName} and start rental tracking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('START RENTAL'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<RentalRequestsState>().startRental(request);
      context.read<NotificationsState>().add(
        audience: UserRole.renter,
        title: 'Rental started',
        message: '${request.item.name} is now an active rental.',
        kind: NotificationKind.status,
        relatedRequestId: request.id,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rental is now active.')));
    }
  }

  Future<void> _confirmReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Item Return?'),
        content: Text(
          'Confirm that ${request.item.name} was returned by '
          '${request.renterName} and complete this rental?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM RETURN'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      context.read<RentalRequestsState>().confirmReturn(request);
      context.read<NotificationsState>().add(
        audience: UserRole.renter,
        title: 'Return confirmed',
        message: '${request.item.name} was returned successfully.',
        kind: NotificationKind.returnUpdate,
        relatedRequestId: request.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item return confirmed. Rental completed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<RentalRequestsState>();
    final message = request.message.trim();
    final pending = request.status == RentalRequestStatus.pending;
    final approved = request.status == RentalRequestStatus.approved;
    final returnRequested =
        request.status == RentalRequestStatus.returnRequested;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.xl),
                        ),
                        child: ItemImage(
                          imageUrl: request.item.imageUrl,
                          icon: request.item.icon,
                          height: 240,
                          width: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        left: AppSpacing.md,
                        child: SafeArea(
                          bottom: false,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: .94),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.item.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Requested by ${request.renterName}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        RequestReviewSection(
                          items: [
                            ReviewItem(
                              label: 'Rental Period',
                              value: request.rentalPeriodLabel,
                            ),
                            ReviewItem(
                              label: 'Duration',
                              value: request.durationLabel,
                            ),
                            ReviewItem(
                              label: 'Rental Price',
                              value: request.item.priceLabel,
                            ),
                            ReviewItem(
                              label: 'Estimated Total',
                              value: request.estimatedTotalLabel,
                              emphasize: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _InfoBox(
                          label: 'MESSAGE',
                          text: message.isEmpty
                              ? 'No message added.'
                              : '“$message”',
                        ),
                        if (request.status == RentalRequestStatus.rejected &&
                            request.rejectionReason.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoBox(
                            label: 'REJECTION REASON',
                            text: request.rejectionReason,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        RequestStatusBadge(status: request.status),
                        const SizedBox(height: 8),
                        Text(
                          request.status.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RentalStatusTimeline(request: request),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pending)
            _ApproveRejectBar(onReject: _reject, onApprove: _approve),
          if (approved) _StartRentalBar(onStart: _startRental),
          if (returnRequested) _ConfirmReturnBar(onConfirm: _confirmReturn),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String text;

  const _InfoBox({required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    ),
  );
}

class _ApproveRejectBar extends StatelessWidget {
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _ApproveRejectBar({required this.onReject, required this.onApprove});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('REJECT REQUEST'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onApprove,
              child: const Text('APPROVE REQUEST'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StartRentalBar extends StatelessWidget {
  final VoidCallback onStart;

  const _StartRentalBar({required this.onStart});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: ElevatedButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('START RENTAL'),
      ),
    ),
  );
}

class _ConfirmReturnBar extends StatelessWidget {
  final VoidCallback onConfirm;

  const _ConfirmReturnBar({required this.onConfirm});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: ElevatedButton.icon(
        onPressed: onConfirm,
        icon: const Icon(Icons.assignment_turned_in_rounded),
        label: const Text('CONFIRM ITEM RETURN'),
      ),
    ),
  );
}
