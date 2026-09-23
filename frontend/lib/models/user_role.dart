import 'dart:typed_data';

/// The three RentMark user roles.
///
/// Admin exists for Login only — it is intentionally excluded from public
/// Registration (see [MockAccounts]).
enum UserRole { renter, owner, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.renter:
        return 'Renter';
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// A local, in-memory mock user — no backend, no persistence.
class MockUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String community;
  final Uint8List? profileImageBytes;
  final String phone;
  final String bio;
  final DateTime? joinedAt;
  final bool identityVerified;

  const MockUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.community,
    this.profileImageBytes,
    this.phone = '',
    this.bio = '',
    this.joinedAt,
    this.identityVerified = false,
  });
}

/// Mock accounts used to demonstrate role-based login for Phase 1.
///
/// Any password is accepted — this is local/mock state only, never real
/// authentication.
class MockAccounts {
  MockAccounts._();

  static const List<MockUser> all = [
    MockUser(
      id: 'user-renter-001',
      name: 'Mark',
      email: 'renter@example.com',
      role: UserRole.renter,
      community: 'Davao Community',
    ),
    MockUser(
      id: 'user-owner-001',
      name: 'Sample Owner',
      email: 'owner@example.com',
      role: UserRole.owner,
      community: 'Davao Community',
    ),
    MockUser(
      id: 'user-admin-001',
      name: 'System Administrator',
      email: 'admin@example.com',
      role: UserRole.admin,
      community: 'Davao Community',
    ),
  ];

  /// Looks up a mock user by email (case-insensitive). Returns null if the
  /// email doesn't match one of the three seeded mock accounts.
  static MockUser? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in all) {
      if (user.email == normalized) return user;
    }
    return null;
  }
}
