import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/rental_pricing.dart';

import 'package:provider/provider.dart';

import '../models/rental_item.dart';
import '../models/owner_listing.dart';
import '../models/rental_request.dart';
import '../models/user_role.dart';
import '../state/admin_state.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/request_status_badge.dart';
import 'welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminName;

  const AdminDashboardScreen({super.key, required this.adminName});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();
    final pages = [
      _AdminOverview(adminName: widget.adminName),
      const _UsersManagement(),
      const _ListingsManagement(),
      const _RentalReports(),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = Stack(
          children: [
            IndexedStack(index: _index, children: pages),
            if (admin.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (admin.error != null && !admin.isLoading)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Material(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(admin.error!)),
                        TextButton(
                          onPressed: admin.reload,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
        return Scaffold(
          backgroundColor: AppColors.background,
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      extended: constraints.maxWidth >= 1050,
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.admin_panel_settings_rounded),
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline_rounded),
                          selectedIcon: Icon(Icons.people_rounded),
                          label: Text('Users'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.inventory_2_outlined),
                          selectedIcon: Icon(Icons.inventory_2_rounded),
                          label: Text('Listings'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.analytics_outlined),
                          selectedIcon: Icon(Icons.analytics_rounded),
                          label: Text('Reports'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (index) =>
                      setState(() => _index = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: 'Users',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2_rounded),
                      label: 'Listings',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics_rounded),
                      label: 'Reports',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AdminOverview extends StatelessWidget {
  final String adminName;

  const _AdminOverview({required this.adminName});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();
    final users = admin.users;
    final requests = admin.requests;
    final listingCount = admin.listings.length;
    final active = requests
        .where((request) => request.status == RentalRequestStatus.active)
        .length;
    final returns = requests
        .where(
          (request) => request.status == RentalRequestStatus.returnRequested,
        )
        .length;
    final completed = requests
        .where((request) => request.status == RentalRequestStatus.completed)
        .length;
    final pending = requests
        .where((request) => request.status == RentalRequestStatus.pending)
        .length;
    final conversion = requests.isEmpty
        ? 0
        : (completed / requests.length * 100).round();
    return _AdminPage(
      title: 'Admin Dashboard',
      trailing: IconButton(
        tooltip: 'Log out',
        onPressed: () {
          context.read<AuthState>().logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded),
      ),
      children: [
        Text(
          'Welcome, $adminName',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text('Monitor RentMark activity and prototype records.'),
        const SizedBox(height: AppSpacing.lg),
        _MetricGrid(
          metrics: [
            _Metric('Users', '${users.length}', Icons.people_rounded),
            _Metric('Listings', '$listingCount', Icons.inventory_2_rounded),
            _Metric(
              'Requests',
              '${requests.length}',
              Icons.receipt_long_rounded,
            ),
            _Metric('Active', '$active', Icons.play_circle_outline_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Platform health', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _HealthCard(
          pending: pending,
          active: active,
          completed: completed,
          conversion: conversion,
        ),
        const SizedBox(height: AppSpacing.lg),
        _NoticeCard(
          icon: Icons.keyboard_return_rounded,
          title: '$returns returns awaiting confirmation',
          message: 'Review the rental records before following up with owners.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _NoticeCard(
          icon: Icons.shield_outlined,
          title: 'Protected administration',
          message: 'Backend moderation changes persist and require administrator access.',
        ),
      ],
    );
  }
}

class _UsersManagement extends StatefulWidget {
  const _UsersManagement();

  @override
  State<_UsersManagement> createState() => _UsersManagementState();
}

class _UsersManagementState extends State<_UsersManagement> {
  String query = '';
  UserRole? role;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminState>();
    final allUsers = state.users
        .where((user) => user.role != UserRole.admin)
        .toList();
    final normalized = query.trim().toLowerCase();
    final users = allUsers.where((user) {
      return (role == null || user.role == role) &&
          (normalized.isEmpty ||
              user.name.toLowerCase().contains(normalized) ||
              user.email.toLowerCase().contains(normalized) ||
              user.community.toLowerCase().contains(normalized));
    }).toList();
    return _AdminPage(
      title: 'User Management',
      children: [
        _AdminSearch(
          hint: 'Search name, email, or community',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _RoleFilterBar(
          selectedRole: role,
          allCount: allUsers.length,
          renterCount: allUsers
              .where((user) => user.role == UserRole.renter)
              .length,
          ownerCount: allUsers
              .where((user) => user.role == UserRole.owner)
              .length,
          onChanged: (value) => setState(() => role = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResultHeader(label: 'Accounts', count: users.length),
        const SizedBox(height: AppSpacing.md),
        if (users.isEmpty)
          const _AdminEmpty(
            icon: Icons.person_search_outlined,
            title: 'No matching users',
            message: 'Try a different search or role filter.',
          ),
        ...users.map((user) {
          final suspended = state.isSuspended(user.email);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ManagementCard(
              icon: Icons.person_outline_rounded,
              title: user.name,
              subtitle: '${user.role.label} • ${user.email}\n${user.community}',
              status: suspended ? 'Suspended' : 'Active',
              imageBytes: user.profileImageBytes,
              destructive: suspended,
              actionLabel: suspended ? 'RESTORE' : 'SUSPEND',
              onAction: () async {
                final result = await _moderationDialog(
                  context,
                  title: suspended
                      ? 'Restore ${user.name}?'
                      : 'Suspend ${user.name}?',
                  message: suspended
                      ? 'This account will regain access to RentMark.'
                      : 'This account will be unable to log in until restored.',
                  action: suspended ? 'RESTORE' : 'SUSPEND',
                  requireReason: !suspended,
                );
                if (result == null || !context.mounted) return;
                try {
                  await context.read<AdminState>().setUserSuspended(
                    user,
                    !suspended,
                    result,
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account moderation could not be updated.'),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} was updated.')),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ListingsManagement extends StatefulWidget {
  const _ListingsManagement();

  @override
  State<_ListingsManagement> createState() => _ListingsManagementState();
}

class _ListingsManagementState extends State<_ListingsManagement> {
  String query = '';
  bool hiddenOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminState>();
    final normalized = query.trim().toLowerCase();
    final source = state.listings;
    final items = source.where((item) {
      final hidden = item.moderationStatus == ListingModerationStatus.hidden;
      return (!hiddenOnly || hidden) &&
          (normalized.isEmpty ||
              item.name.toLowerCase().contains(normalized) ||
              item.category.label.toLowerCase().contains(normalized) ||
              item.community.toLowerCase().contains(normalized));
    }).toList();
    return _AdminPage(
      title: 'Listing Management',
      children: [
        _AdminSearch(
          hint: 'Search listing, category, or community',
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ResultHeader(label: 'Listings', count: items.length),
            ),
            FilterChip(
              label: const Text('Hidden only'),
              selected: hiddenOnly,
              onSelected: (value) => setState(() => hiddenOnly = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const _AdminEmpty(
            icon: Icons.inventory_2_outlined,
            title: 'No matching listings',
            message: 'Try changing the search or moderation filter.',
          ),
        ...items.map((item) {
          final hidden =
              item.moderationStatus == ListingModerationStatus.hidden;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ManagementCard(
              icon: item.icon,
              title: item.name,
              subtitle:
                  '${item.category.label} • ${item.priceLabel}\n${item.community}',
              status: hidden ? 'Hidden by admin' : 'Visible',
              destructive: hidden,
              actionLabel: hidden ? 'RESTORE' : 'HIDE',
              onAction: () async {
                final reason = await _moderationDialog(
                  context,
                  title: hidden
                      ? 'Restore ${item.name}?'
                      : 'Hide ${item.name}?',
                  message: hidden
                      ? 'Renters will be able to discover this listing again.'
                      : 'This listing will disappear from renter discovery.',
                  action: hidden ? 'RESTORE' : 'HIDE',
                  requireReason: !hidden,
                );
                if (reason == null || !context.mounted) return;
                try {
                  await state.setListingHidden(item, !hidden, reason);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing moderation could not be updated.'),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} moderation updated.')),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _RentalReports extends StatelessWidget {
  const _RentalReports();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();
    final requests = admin.requests;
    final reviews = admin.reviews;
    final completed = requests
        .where((request) => request.status == RentalRequestStatus.completed)
        .length;
    final rejected = requests
        .where((request) => request.status == RentalRequestStatus.rejected)
        .length;
    final estimatedValue = requests
        .where((request) => request.status != RentalRequestStatus.rejected)
        .fold<double>(0, (sum, request) => sum + request.estimatedTotal);

    return _AdminPage(
      title: 'Reports',
      children: [
        _MetricGrid(
          metrics: [
            _Metric(
              'Total rentals',
              '${requests.length}',
              Icons.receipt_long_rounded,
            ),
            _Metric(
              'Completed',
              '$completed',
              Icons.check_circle_outline_rounded,
            ),
            _Metric('Rejected', '$rejected', Icons.cancel_outlined),
            _Metric('Reviews', '${reviews.length}', Icons.star_outline_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _NoticeCard(
          icon: Icons.payments_outlined,
          title: '${formatPesos(estimatedValue)} estimated rental value',
          message: 'Prototype total based on non-rejected rental requests.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Rental Records', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        if (requests.isEmpty)
          const Text('No rental records available.')
        else
          ...requests.map(
            (request) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.item.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('${request.id} • ${request.renterName}'),
                      ],
                    ),
                  ),
                  RequestStatusBadge(status: request.status),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminPage extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _AdminPage({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    ),
  );
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
}

class _HealthCard extends StatelessWidget {
  final int pending;
  final int active;
  final int completed;
  final int conversion;

  const _HealthCard({
    required this.pending,
    required this.active,
    required this.completed,
    required this.conversion,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        _HealthRow(
          label: 'Pending review',
          value: pending,
          color: AppColors.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        _HealthRow(
          label: 'Active rentals',
          value: active,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        _HealthRow(
          label: 'Completed',
          value: completed,
          color: AppColors.success,
        ),
        const Divider(height: AppSpacing.xl),
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Request completion rate',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$conversion%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HealthRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(label)),
      Text('$value', style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _AdminSearch extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _AdminSearch({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: const Icon(Icons.tune_rounded),
    ),
  );
}

class _RoleFilterBar extends StatelessWidget {
  final UserRole? selectedRole;
  final int allCount;
  final int renterCount;
  final int ownerCount;
  final ValueChanged<UserRole?> onChanged;

  const _RoleFilterBar({
    required this.selectedRole,
    required this.allCount,
    required this.renterCount,
    required this.ownerCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        _RoleFilterOption(
          label: 'All',
          count: allCount,
          selected: selectedRole == null,
          onTap: () => onChanged(null),
        ),
        _RoleFilterOption(
          label: 'Renters',
          count: renterCount,
          selected: selectedRole == UserRole.renter,
          onTap: () => onChanged(UserRole.renter),
        ),
        _RoleFilterOption(
          label: 'Owners',
          count: ownerCount,
          selected: selectedRole == UserRole.owner,
          onTap: () => onChanged(UserRole.owner),
        ),
      ],
    ),
  );
}

class _RoleFilterOption extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _RoleFilterOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      label: '$label, $count accounts',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: selected ? Border.all(color: AppColors.primarySoft) : null,
            boxShadow: selected ? AppShadows.card : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ResultHeader extends StatelessWidget {
  final String label;
  final int count;

  const _ResultHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(width: AppSpacing.sm),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _AdminEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AdminEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      children: [
        Icon(icon, size: 42, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

Future<String?> _moderationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  required bool requireReason,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ModerationDialog(
      title: title,
      message: message,
      action: action,
      requireReason: requireReason,
    ),
  );
}

class _ModerationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String action;
  final bool requireReason;

  const _ModerationDialog({
    required this.title,
    required this.message,
    required this.action,
    required this.requireReason,
  });

  @override
  State<_ModerationDialog> createState() => _ModerationDialogState();
}

class _ModerationDialogState extends State<_ModerationDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (widget.requireReason && reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, widget.requireReason ? reason : widget.action);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(
      widget.requireReason
          ? Icons.gpp_maybe_outlined
          : Icons.verified_user_outlined,
      color: widget.requireReason ? AppColors.error : AppColors.primary,
    ),
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (widget.requireReason) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Moderation reason',
                hintText: 'Explain why this action is needed',
                errorText: _showError ? 'A reason is required.' : null,
              ),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(
        style: widget.requireReason
            ? FilledButton.styleFrom(backgroundColor: AppColors.error)
            : null,
        onPressed: _submit,
        child: Text(widget.action),
      ),
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
    ),
    itemCount: metrics.length,
    itemBuilder: (_, index) {
      final metric = metrics[index];
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(metric.icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    metric.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySofter,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(message),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final Uint8List? imageBytes;
  final String title;
  final String subtitle;
  final String status;
  final String actionLabel;
  final bool destructive;
  final VoidCallback onAction;

  const _ManagementCard({
    required this.icon,
    this.imageBytes,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actionLabel,
    required this.destructive,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            image: imageBytes == null
                ? null
                : DecorationImage(
                    image: MemoryImage(imageBytes!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: imageBytes == null
              ? Icon(icon, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(subtitle),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: destructive
                      ? AppColors.errorSoft
                      : const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: destructive ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.success : AppColors.error,
          ),
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
