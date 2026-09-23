import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../screens/renter_shell.dart';
import '../screens/owner_shell.dart';
import '../screens/admin_dashboard_screen.dart';

/// Resolves the correct post-login destination for an authenticated user.
///
/// Renter lands on [RenterShell] (Phase 2+), Owner lands on
/// [OwnerShell], and Admin lands on the Phase 10 dashboard.
Widget destinationForRole(MockUser user) {
  switch (user.role) {
    case UserRole.renter:
      return RenterShell(
        userName: user.name,
        community: user.community,
        profileImageBytes: user.profileImageBytes,
      );
    case UserRole.owner:
      return OwnerShell(
        ownerName: user.name,
        community: user.community,
        profileImageBytes: user.profileImageBytes,
      );
    case UserRole.admin:
      return AdminDashboardScreen(adminName: user.name);
  }
}
