import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../models/rental_request.dart';
import '../state/rental_requests_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/owner_rental_request_card.dart';
import '../widgets/empty_state.dart';
import 'owner_request_details_screen.dart';

enum _OwnerRequestFilter {
  all,
  pending,
  approved,
  active,
  returnRequested,
  completed,
  rejected,
}

enum _OwnerRequestSort { newest, rentalDate, highestValue }

class OwnerRequestsScreen extends StatefulWidget {
  final bool showBack;
  const OwnerRequestsScreen({super.key, this.showBack = true});

  @override
  State<OwnerRequestsScreen> createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen> {
  _OwnerRequestFilter _filter = _OwnerRequestFilter.all;
  _OwnerRequestSort _sort = _OwnerRequestSort.newest;

  List<RentalRequest> _visible(List<RentalRequest> all) {
    final filtered = switch (_filter) {
      _OwnerRequestFilter.all => all.toList(),
      _OwnerRequestFilter.pending =>
        all.where((r) => r.status == RentalRequestStatus.pending).toList(),
      _OwnerRequestFilter.approved =>
        all.where((r) => r.status == RentalRequestStatus.approved).toList(),
      _OwnerRequestFilter.active =>
        all.where((r) => r.status == RentalRequestStatus.active).toList(),
      _OwnerRequestFilter.returnRequested =>
        all
            .where((r) => r.status == RentalRequestStatus.returnRequested)
            .toList(),
      _OwnerRequestFilter.completed =>
        all.where((r) => r.status == RentalRequestStatus.completed).toList(),
      _OwnerRequestFilter.rejected =>
        all.where((r) => r.status == RentalRequestStatus.rejected).toList(),
    };
    filtered.sort(
      (a, b) => switch (_sort) {
        _OwnerRequestSort.newest => b.requestedAt.compareTo(a.requestedAt),
        _OwnerRequestSort.rentalDate => a.startDate.compareTo(b.startDate),
        _OwnerRequestSort.highestValue => b.estimatedTotal.compareTo(
          a.estimatedTotal,
        ),
      },
    );
    return filtered;
  }

  String get _heading {
    switch (_filter) {
      case _OwnerRequestFilter.all:
        return 'All Requests';
      case _OwnerRequestFilter.pending:
        return 'Pending Requests';
      case _OwnerRequestFilter.approved:
        return 'Approved Requests';
      case _OwnerRequestFilter.active:
        return 'Active Rentals';
      case _OwnerRequestFilter.returnRequested:
        return 'Returns to Confirm';
      case _OwnerRequestFilter.completed:
        return 'Completed Rentals';
      case _OwnerRequestFilter.rejected:
        return 'Rejected Requests';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRequests = context.watch<RentalRequestsState>().requests;
    final requests = _visible(allRequests);
    int count(RentalRequestStatus status) =>
        allRequests.where((request) => request.status == status).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Rental Requests',
                subtitle: 'Review requests and track approved rentals.',
                showBack: widget.showBack,
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', allRequests.length, _OwnerRequestFilter.all),
                    const SizedBox(width: 8),
                    _chip(
                      'Pending',
                      count(RentalRequestStatus.pending),
                      _OwnerRequestFilter.pending,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Approved',
                      count(RentalRequestStatus.approved),
                      _OwnerRequestFilter.approved,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Active',
                      count(RentalRequestStatus.active),
                      _OwnerRequestFilter.active,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Returns',
                      count(RentalRequestStatus.returnRequested),
                      _OwnerRequestFilter.returnRequested,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Completed',
                      count(RentalRequestStatus.completed),
                      _OwnerRequestFilter.completed,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Rejected',
                      count(RentalRequestStatus.rejected),
                      _OwnerRequestFilter.rejected,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _heading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<_OwnerRequestSort>(
                    tooltip: 'Sort requests',
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    icon: const Icon(Icons.sort_rounded),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _OwnerRequestSort.newest,
                        child: Text('Newest request'),
                      ),
                      PopupMenuItem(
                        value: _OwnerRequestSort.rentalDate,
                        child: Text('Rental date'),
                      ),
                      PopupMenuItem(
                        value: _OwnerRequestSort.highestValue,
                        child: Text('Highest value'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: requests.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No requests here',
                            message:
                                'There are no ${_heading.toLowerCase()} right now.',
                            actionLabel: 'VIEW ALL',
                            onAction: () => setState(
                              () => _filter = _OwnerRequestFilter.all,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        itemCount: requests.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) => OwnerRentalRequestCard(
                          request: requests[i],
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OwnerRequestDetailsScreen(
                                  request: requests[i],
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, int count, _OwnerRequestFilter value) => InkWell(
    onTap: () => setState(() => _filter = value),
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _filter == value ? AppColors.primary : AppColors.primarySofter,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _filter == value ? Colors.white : AppColors.textSecondary,
        ),
      ),
    ),
  );
}
