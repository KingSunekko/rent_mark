import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import '../models/rental_pricing.dart';
import '../models/rental_request.dart';
import '../state/auth_state.dart';
import '../state/rental_requests_state.dart';
import '../state/notifications_state.dart';
import '../models/app_notification.dart';
import '../models/user_role.dart';
import '../widgets/screen_header.dart';
import '../widgets/request_review_section.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/date_selection_field.dart';
import 'request_confirmation_screen.dart';
import '../widgets/rental_step_indicator.dart';
import '../services/rental_request_api_service.dart';

/// Phase 4C — Review Rental Request.
///
/// Reached from the Rental Request form's "REVIEW REQUEST" once dates
/// are valid. Shows the finalized request details and lets the renter go
/// back to edit, or submit — which creates a real [RentalRequest] in
/// [RentalRequestsState] with PENDING status and opens a temporary
/// [RequestConfirmationScreen]. A full "My Rentals" list is Phase 4D.
class RentalRequestReviewScreen extends StatefulWidget {
  final RentalItem item;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final num estimatedTotal;
  final String message;
  final String pickupMethod;

  const RentalRequestReviewScreen({
    super.key,
    required this.item,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.estimatedTotal,
    required this.message,
    required this.pickupMethod,
  });

  @override
  State<RentalRequestReviewScreen> createState() =>
      _RentalRequestReviewScreenState();
}

class _RentalRequestReviewScreenState extends State<RentalRequestReviewScreen> {
  final _submissionId = RentalRequestApiService.newSubmissionId();
  bool _saving = false;
  String? _error;
  RentalItem get item => widget.item;
  DateTime get startDate => widget.startDate;
  DateTime get endDate => widget.endDate;
  int get durationDays => widget.durationDays;
  String get message => widget.message;
  String get pickupMethod => widget.pickupMethod;

  String get _rentalPeriodLabel {
    // Dates shown without the year on this screen, matching the
    // approved review-screen layout ("September 5 – September 7").
    return '${_formatDateNoYear(startDate)} – ${_formatDateNoYear(endDate)}';
  }

  static String _formatDateNoYear(DateTime date) {
    // Strip ", <year>" off the shared formatter's output rather than
    // duplicating its month-name table.
    final full = DateSelectionField.formatDate(date);
    return full.substring(0, full.lastIndexOf(','));
  }

  Future<void> _submit(BuildContext context) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final renterName = context.read<AuthState>().currentUser?.name ?? 'Renter';
    final renterId = context.read<AuthState>().currentUser?.id ?? '';

    try {
      final created = await context.read<RentalRequestsState>().submitRequest(
        RentalRequest(
          id: 'REQ-$_submissionId',
          item: item,
          renterName: renterName,
          renterId: renterId,
          ownerId: item.ownerId,
          startDate: startDate,
          endDate: endDate,
          message: message.trim(),
          pickupMethod: pickupMethod,
          requestedAt: DateTime.now(),
        ),
        _submissionId,
      );
      if (!context.mounted) return;

      if (!created.isRemote) {
        context.read<NotificationsState>().add(
          audience: UserRole.owner,
          title: 'New rental request',
          message: '$renterName requested ${item.name}.',
          kind: NotificationKind.request,
          relatedRequestId: created.id,
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestConfirmationScreen(request: created),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedMessage = message.trim();

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
              const ScreenHeader(
                title: 'Review Rental Request',
                subtitle:
                    'Check your details before sending this to the owner.',
              ),
              const SizedBox(height: AppSpacing.md),
              const RentalStepIndicator(currentStep: 2),
              const SizedBox(height: AppSpacing.xl),
              RequestReviewSection(
                items: [
                  ReviewItem(label: 'Item', value: item.name),
                  ReviewItem(label: 'Rental Period', value: _rentalPeriodLabel),
                  ReviewItem(
                    label: 'Duration',
                    value:
                        '$durationDays ${durationDays == 1 ? 'day' : 'days'}',
                  ),
                  ReviewItem(label: 'Price', value: item.priceLabel),
                  if (item.discountPercent > 0) ...[
                    ReviewItem(
                      label: 'Regular rate',
                      value: item.originalPriceLabel,
                    ),
                    ReviewItem(
                      label: 'Owner discount',
                      value: '${item.discountPercent}% every day',
                    ),
                    ReviewItem(
                      label: 'You save',
                      value: formatPesos(
                        item.pricePerDay * durationDays -
                            item.totalForDays(durationDays),
                      ),
                    ),
                  ],
                  ReviewItem(label: 'Pickup & Return', value: pickupMethod),
                  ReviewItem(
                    label: 'Estimated Total',
                    value: formatPesos(item.totalForDays(durationDays)),
                    emphasize: true,
                  ),
                  ReviewItem(
                    label: 'Message',
                    value: trimmedMessage.isEmpty
                        ? 'No message added.'
                        : trimmedMessage,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'SUBMIT REQUEST',
                isLoading: _saving,
                onPressed: () => _submit(context),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SecondaryButton(
                label: 'EDIT REQUEST',
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
