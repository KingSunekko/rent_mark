import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_item.dart';
import '../widgets/screen_header.dart';
import '../widgets/rental_item_summary.dart';
import '../widgets/date_selection_field.dart';
import '../widgets/rental_duration_display.dart';
import '../widgets/rental_cost_summary.dart';
import '../widgets/renter_notes_field.dart';
import '../widgets/primary_button.dart';
import 'rental_request_review_screen.dart';
import '../state/rental_requests_state.dart';
import '../state/auth_state.dart';
import '../widgets/rental_step_indicator.dart';

/// Phase 4C — Rental Request screen with real date validation, live cost
/// calculation, and a functional path to Review.
///
/// Reached from Item Details via "REQUEST TO RENT". Start/End dates are
/// picked via `showDatePicker`; duration and estimated cost are
/// calculated live from the picked dates. "REVIEW REQUEST" validates the
/// dates, then opens [RentalRequestReviewScreen] with the finalized
/// request details.
class RentalRequestScreen extends StatefulWidget {
  final RentalItem item;

  const RentalRequestScreen({super.key, required this.item});

  @override
  State<RentalRequestScreen> createState() => _RentalRequestScreenState();
}

class _RentalRequestScreenState extends State<RentalRequestScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startDateError;
  String? _endDateError;
  final _notesController = TextEditingController();
  String _pickupMethod = 'Community meetup';
  bool _acceptedTerms = false;
  String? _termsError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasValidRange =>
      _startDate != null &&
      _endDate != null &&
      !_endDate!.isBefore(_startDate!);

  /// Inclusive day count (Sep 5 → Sep 7 = 3 days), matching how the rest
  /// of RentMark counts rental duration.
  int? get _durationDays =>
      _hasValidRange ? _endDate!.difference(_startDate!).inDays + 1 : null;

  double? get _estimatedTotal {
    final days = _durationDays;
    return days != null ? widget.item.totalForDays(days) : null;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _startDateError = null;
      // Re-validate the existing end date against the new start date.
      _endDateError = (_endDate != null && _endDate!.isBefore(picked))
          ? 'End date cannot be before start date.'
          : null;
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final base = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? base,
      firstDate: base,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _endDateError = picked.isBefore(base)
          ? 'End date cannot be before start date.'
          : null;
    });
  }

  void _continue() {
    if (!widget.item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is currently unavailable.')),
      );
      return;
    }
    if (widget.item.ownerId == context.read<AuthState>().currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot rent your own item.')),
      );
      return;
    }
    setState(() {
      _startDateError = _startDate == null
          ? 'Please select a start date.'
          : null;
      _endDateError = _endDate == null
          ? 'Please select an end date.'
          : (_startDate != null && _endDate!.isBefore(_startDate!)
                ? 'End date cannot be before start date.'
                : null);
      _termsError = _acceptedTerms
          ? null
          : 'Please agree to the rental terms before continuing.';
    });

    if (_startDateError != null || _endDateError != null || _termsError != null) {
      return;
    }

    if (context.read<RentalRequestsState>().hasDateConflict(
      itemId: widget.item.id,
      startDate: _startDate!,
      endDate: _endDate!,
    )) {
      setState(
        () => _endDateError =
            'This item already has a rental during the selected dates.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RentalRequestReviewScreen(
          item: widget.item,
          startDate: _startDate!,
          endDate: _endDate!,
          durationDays: _durationDays!,
          estimatedTotal: _estimatedTotal!,
          message: _notesController.text,
          pickupMethod: _pickupMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

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
                title: 'Request to Rent',
                subtitle:
                    'Choose when you need this item and review your request.',
              ),
              const SizedBox(height: AppSpacing.md),
              const RentalStepIndicator(currentStep: 1),
              const SizedBox(height: AppSpacing.lg),
              RentalItemSummary(item: item),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Rental Dates',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              DateSelectionField(
                label: 'Start Date',
                value: _startDate,
                placeholder: 'Select start date',
                errorText: _startDateError,
                onTap: _pickStartDate,
              ),
              const SizedBox(height: AppSpacing.md),
              DateSelectionField(
                label: 'End Date',
                value: _endDate,
                placeholder: 'Select end date',
                errorText: _endDateError,
                onTap: _pickEndDate,
              ),
              const SizedBox(height: AppSpacing.md),
              RentalDurationDisplay(days: _durationDays),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Pickup & Return',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _pickupMethod,
                items: const [
                  DropdownMenuItem(
                    value: 'Community meetup',
                    child: Text('Community meetup'),
                  ),
                  DropdownMenuItem(
                    value: 'Pickup from owner',
                    child: Text('Pickup from owner'),
                  ),
                  DropdownMenuItem(
                    value: 'Local delivery',
                    child: Text('Local delivery'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _pickupMethod = value ?? _pickupMethod),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.handshake_outlined),
                  labelText: 'Method',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              RenterNotesField(controller: _notesController),
              const SizedBox(height: AppSpacing.xl),
              RentalCostSummary(
                pricePerDayLabel: item.priceLabel,
                originalPriceLabel: item.originalPriceLabel,
                discountPercent: item.discountPercent,
                durationDays: _durationDays,
                estimatedTotal: _estimatedTotal,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _termsError == null
                        ? AppColors.border
                        : AppColors.error,
                  ),
                ),
                child: CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) => setState(() {
                    _acceptedTerms = value ?? false;
                    if (_acceptedTerms) _termsError = null;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I agree to the rental terms'),
                  subtitle: Text(
                    _termsError ?? 'I will return the item on time and in the same condition.',
                    style: TextStyle(
                      color: _termsError == null
                          ? AppColors.textSecondary
                          : AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'REVIEW REQUEST', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}
