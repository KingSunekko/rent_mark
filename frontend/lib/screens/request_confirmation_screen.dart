import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import '../widgets/request_status_badge.dart';
import '../widgets/primary_button.dart';
import '../widgets/date_selection_field.dart';
import '../widgets/rental_step_indicator.dart';

/// Confirmation screen shown right after a rental request is submitted.
///
/// Deliberately simple — this is NOT an approval or a confirmed rental,
/// only an acknowledgement that the request reached the owner and is now
/// Pending. A fuller "View Request" → My Rentals hookup arrives once
/// that list exists (Phase 4D); for now the only action is leaving.
class RequestConfirmationScreen extends StatelessWidget {
  final RentalRequest request;

  const RequestConfirmationScreen({super.key, required this.request});

  String get _rentalPeriodLabel {
    // No-year format, matching the Review screen's rental period style.
    String noYear(DateTime date) {
      final full = DateSelectionField.formatDate(date);
      return full.substring(0, full.lastIndexOf(','));
    }

    return '${noYear(request.startDate)} – ${noYear(request.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RentalStepIndicator(currentStep: 3),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Request Submitted',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your rental request has been sent to the item owner.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rentalPeriodLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.durationLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          request.estimatedTotalLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        RequestStatusBadge(status: request.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'BACK TO ITEMS',
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
