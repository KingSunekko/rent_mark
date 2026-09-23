import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/renter_bottom_navigation.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_rentals_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';
import '../models/user_role.dart';

/// Root shell for the Renter role — hosts the bottom navigation and swaps
/// between Home, Search, Rentals, Notifications, and Profile. Home,
/// All five destinations are functional through Phase 10.
class RenterShell extends StatefulWidget {
  final String userName;
  final String community;
  final Uint8List? profileImageBytes;

  const RenterShell({
    super.key,
    required this.userName,
    required this.community,
    this.profileImageBytes,
  });

  @override
  State<RenterShell> createState() => _RenterShellState();
}

class _RenterShellState extends State<RenterShell> {
  int _index = 0;

  late final List<Widget> _tabs = [
    HomeScreen(
      userName: widget.userName,
      community: widget.community,
      profileImageBytes: widget.profileImageBytes,
    ),
    SearchScreen(onBack: () => setState(() => _index = 0)),
    MyRentalsScreen(onBrowseItems: () => setState(() => _index = 0)),
    NotificationsScreen(
      role: UserRole.renter,
      onBack: () => setState(() => _index = 0),
    ),
    UserProfileScreen(
      name: widget.userName,
      community: widget.community,
      role: UserRole.renter,
      isCurrentUser: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: RenterBottomNavigation(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}
