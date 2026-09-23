import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_theme.dart';
import 'notifications_screen.dart';
import 'owner_home_screen.dart';
import 'owner_listings_screen.dart';
import 'owner_requests_screen.dart';
import 'user_profile_screen.dart';

/// Persistent workspace navigation for owners.
class OwnerShell extends StatefulWidget {
  final String ownerName;
  final String community;
  final Uint8List? profileImageBytes;

  const OwnerShell({
    super.key,
    required this.ownerName,
    required this.community,
    this.profileImageBytes,
  });

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
    OwnerHomeScreen(
      ownerName: widget.ownerName,
      community: widget.community,
      profileImageBytes: widget.profileImageBytes,
    ),
    const OwnerRequestsScreen(showBack: false),
    OwnerListingsScreen(community: widget.community, showBack: false),
    NotificationsScreen(
      role: UserRole.owner,
      onBack: () => setState(() => _index = 0),
    ),
    UserProfileScreen(
      name: widget.ownerName,
      community: widget.community,
      role: UserRole.owner,
      isCurrentUser: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
