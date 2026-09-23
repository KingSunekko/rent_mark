import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental_request.dart';
import '../state/reviews_state.dart';
import '../state/notifications_state.dart';
import '../models/app_notification.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/screen_header.dart';
import '../services/auth_api_service.dart';

class ReviewFormScreen extends StatefulWidget {
  final RentalRequest request;

  const ReviewFormScreen({super.key, required this.request});

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_rating == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final review = await context.read<ReviewsState>().submit(
        request: widget.request,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      if (review == null) {
        setState(() => _error = 'This rental cannot be reviewed again.');
        return;
      }
      if (!review.isRemote) {
        context.read<NotificationsState>().add(
          audience: UserRole.owner,
          title: 'New review received',
          message:
              '${widget.request.renterName} reviewed ${widget.request.item.name}.',
          kind: NotificationKind.review,
          relatedRequestId: widget.request.id,
        );
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException
              ? error.message
              : 'The review could not be submitted. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              title: 'Rate Your Rental',
              subtitle: 'Share your experience with the item and owner.',
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request.item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('Owner: ${widget.request.item.ownerName}'),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'YOUR RATING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() {
                          _rating = index + 1;
                          _error = null;
                        }),
                        icon: Icon(
                          index < _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 38,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _commentController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Written review (optional)',
                      hintText: 'Was the item accurate and easy to rent?',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'SUBMIT REVIEW',
              onPressed: _submit,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    ),
  );
}
