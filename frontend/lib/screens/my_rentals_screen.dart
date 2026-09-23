import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental_request.dart';
import '../state/auth_state.dart';
import '../state/rental_requests_state.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/rental_request_card.dart';
import '../widgets/filter_pill.dart';
import 'rental_request_details_screen.dart';

enum _RentalTab { upcoming, active, returns, completed, cancelled }

class MyRentalsScreen extends StatefulWidget {
  final VoidCallback? onBrowseItems;
  const MyRentalsScreen({super.key, this.onBrowseItems});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  _RentalTab tab = _RentalTab.upcoming;

  bool _matches(RentalRequest request, _RentalTab value) {
    switch (value) {
      case _RentalTab.upcoming:
        return request.status == RentalRequestStatus.pending ||
            request.status == RentalRequestStatus.approved;
      case _RentalTab.active:
        return request.status == RentalRequestStatus.active;
      case _RentalTab.returns:
        return request.status == RentalRequestStatus.returnRequested;
      case _RentalTab.completed:
        return request.status == RentalRequestStatus.completed;
      case _RentalTab.cancelled:
        return request.status == RentalRequestStatus.rejected;
    }
  }

  String _label(_RentalTab value) {
    switch (value) {
      case _RentalTab.upcoming:
        return 'Upcoming';
      case _RentalTab.active:
        return 'Active';
      case _RentalTab.returns:
        return 'Returns';
      case _RentalTab.completed:
        return 'Completed';
      case _RentalTab.cancelled:
        return 'Cancelled';
    }
  }

  String _nextAction(RentalRequest request) {
    switch (request.status) {
      case RentalRequestStatus.pending:
        return 'WAITING FOR OWNER';
      case RentalRequestStatus.approved:
        return 'VIEW APPROVAL';
      case RentalRequestStatus.active:
        return 'REQUEST RETURN';
      case RentalRequestStatus.returnRequested:
        return 'TRACK RETURN';
      case RentalRequestStatus.completed:
        return 'VIEW OR REVIEW';
      case RentalRequestStatus.rejected:
        return 'VIEW DETAILS';
    }
  }

  String? _countdown(RentalRequest request) {
    if (request.status != RentalRequestStatus.active) return null;
    final days = request.endDate.difference(DateTime.now()).inDays + 1;
    if (days < 0) return 'Rental period has ended';
    if (days == 0) return 'Due today';
    return '$days day${days == 1 ? ' remaining' : 's remaining'}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    final all = context
        .watch<RentalRequestsState>()
        .requests
        .where(
          (request) => request.renterId.isNotEmpty
              ? request.renterId == user?.id
              : request.renterName == user?.name,
        )
        .toList();
    final visible = all.where((request) => _matches(request, tab)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                'My Rentals',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: _RentalTab.values.map((value) {
                  final count = all.where((r) => _matches(r, value)).length;
                  return FilterPill(
                    selected: tab == value,
                    label: _label(value),
                    count: count,
                    onTap: () => setState(() => tab = value),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No ${_label(tab).toLowerCase()} rentals',
                        message: tab == _RentalTab.upcoming
                            ? 'Browse nearby items and submit a rental request.'
                            : 'Rentals with this status will appear here.',
                        actionLabel: 'BROWSE ITEMS',
                        onAction: tab == _RentalTab.upcoming
                            ? widget.onBrowseItems
                            : null,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, index) {
                        final request = visible[index];
                        final countdown = _countdown(request);
                        return Column(
                          children: [
                            RentalRequestCard(
                              request: request,
                              onTap: () => _open(context, request),
                            ),
                            if (countdown != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                color: AppColors.primarySofter,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 17,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(countdown),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => _open(context, request),
                                icon: Icon(
                                  request.status == RentalRequestStatus.active
                                      ? Icons.keyboard_return_rounded
                                      : request.status ==
                                            RentalRequestStatus.completed
                                      ? Icons.star_outline_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(_nextAction(request)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, RentalRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalRequestDetailsScreen(request: request),
      ),
    );
  }
}
