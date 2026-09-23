import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import '../state/rental_requests_state.dart';
import '../state/reviews_state.dart';
import '../state/notifications_state.dart';
import '../models/app_notification.dart';
import '../models/user_role.dart';
import '../widgets/screen_header.dart';
import '../widgets/request_review_section.dart';
import '../widgets/request_status_badge.dart';
import '../widgets/rental_status_timeline.dart';
import 'review_form_screen.dart';
import '../services/auth_api_service.dart';

/// Renter-side details and Phase 6 rental status tracking.
class RentalRequestDetailsScreen extends StatefulWidget {
  final RentalRequest request;

  const RentalRequestDetailsScreen({super.key, required this.request});

  @override
  State<RentalRequestDetailsScreen> createState() =>
      _RentalRequestDetailsScreenState();
}

class _RentalRequestDetailsScreenState
    extends State<RentalRequestDetailsScreen> {
  RentalRequest get request => widget.request;
  bool _updating = false;

  Future<void> _requestReturn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Item Return?'),
        content: Text(
          'Mark ${request.item.name} as ready to return? The owner will need '
          'to confirm receiving it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REQUEST RETURN'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      setState(() => _updating = true);
      try {
        await context.read<RentalRequestsState>().requestReturn(request);
        if (!mounted) return;
        if (!request.isRemote) {
          context.read<NotificationsState>().add(
            audience: UserRole.owner,
            title: 'Return requested',
            message:
                '${request.renterName} is ready to return ${request.item.name}.',
            kind: NotificationKind.returnUpdate,
            relatedRequestId: request.id,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return request sent to the owner.')),
        );
      } catch (error) {
        if (mounted) {
          final message = error is ApiException
              ? error.message
              : 'The return request could not be sent. Please try again.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      } finally {
        if (mounted) setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<RentalRequestsState>();
    final reviews = context.watch<ReviewsState>();
    final reviewed = reviews.hasReviewed(request.id);
    final trimmedMessage = request.message.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Rental Details'),
              const SizedBox(height: AppSpacing.xl),
              RequestReviewSection(
                items: [
                  ReviewItem(label: 'Item', value: request.item.name),
                  ReviewItem(
                    label: 'Rental Period',
                    value: request.rentalPeriodLabel,
                  ),
                  ReviewItem(label: 'Duration', value: request.durationLabel),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primarySofter,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RequestStatusBadge(status: request.status),
                    const SizedBox(height: 8),
                    Text(
                      request.status.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RentalStatusTimeline(request: request),
              const SizedBox(height: AppSpacing.lg),
              RequestReviewSection(
                items: [
                  ReviewItem(
                    label: 'Message',
                    value: trimmedMessage.isEmpty
                        ? 'No message added.'
                        : trimmedMessage,
                  ),
                ],
              ),
              if (request.status == RentalRequestStatus.active) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySofter,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Finished using this item?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Request a return when the item is ready to be handed back.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _updating ? null : _requestReturn,
                          icon: const Icon(Icons.keyboard_return_rounded),
                          label: Text(
                            _updating ? 'SENDING...' : 'REQUEST ITEM RETURN',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (request.status == RentalRequestStatus.returnRequested) ...[
                const SizedBox(height: AppSpacing.lg),
                const _ReturnMessage(
                  icon: Icons.schedule_rounded,
                  message:
                      'Waiting for the owner to confirm the returned item.',
                ),
              ],
              if (request.status == RentalRequestStatus.completed) ...[
                const SizedBox(height: AppSpacing.lg),
                const _ReturnMessage(
                  icon: Icons.check_circle_outline_rounded,
                  message: 'Return confirmed. This rental is complete.',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: reviewed
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('REVIEW SUBMITTED'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () async {
                            final submitted = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReviewFormScreen(request: request),
                                  ),
                                );
                            if (submitted == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Thank you for your review.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('RATE AND REVIEW'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ReturnMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
