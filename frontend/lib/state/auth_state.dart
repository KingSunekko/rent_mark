
import 'package:flutter/foundation.dart';

import '../models/user_role.dart';
import '../services/api_config.dart';
import '../services/auth_api_service.dart';
import '../data/owner_listings_store.dart';

/// Local, in-memory session state for Phase 1.
///
/// This is intentionally simple — a single ChangeNotifier holding whichever
/// mock user is "logged in" or mid-registration. No backend, no database,
/// no real authentication. State resets on app restart by design.
class AuthState extends ChangeNotifier {
  final AuthApiService _api = AuthApiService();
  MockUser? _currentUser;
  final List<MockUser> _users = List.of(MockAccounts.all);

  // Fields captured during the Register flow, carried into Role Selection.
  String? _pendingName;
  String? _pendingEmail;
  String? _pendingCommunity;
  Uint8List? _pendingProfileImageBytes;
  String? _pendingPassword;

  MockUser? get currentUser => _currentUser;
  List<MockUser> get users => List.unmodifiable(_users);
  String? get accessToken => _api.accessToken;

  MockUser? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in _users) {
      if (user.email.toLowerCase() == normalized) return user;
    }
    return null;
  }

  void loginAs(MockUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<MockUser> login(String email, String password) async {
    final mock = findByEmail(email);
    if (!ApiConfig.enabled || MockAccounts.findByEmail(email) != null) {
      if (mock == null) {
        throw const ApiException('No account matches that email.');
      }
      loginAs(mock);
      return mock;
    }
    final user = await _api.login(email.trim(), password);
    _upsert(user);
    _currentUser = user;
    notifyListeners();
    return user;
  }

  void startRegistration({
    required String name,
    required String email,
    required String community,
    Uint8List? profileImageBytes,
    required String password,
  }) {
    _pendingName = name;
    _pendingEmail = email;
    _pendingCommunity = community;
    _pendingProfileImageBytes = profileImageBytes;
    _pendingPassword = password;
  }

  Future<MockUser> completeRegistration(UserRole role) async {
    var user = MockUser(
      id: 'user-local-${DateTime.now().millisecondsSinceEpoch}',
      name: _pendingName ?? 'New User',
      email: (_pendingEmail ?? '').trim().toLowerCase(),
      role: role,
      community: _pendingCommunity ?? '',
      profileImageBytes: _pendingProfileImageBytes,
      joinedAt: DateTime.now(),
    );
    if (ApiConfig.enabled) {
      user = await _api.register(
        email: user.email,
        password: _pendingPassword ?? '',
        name: user.name,
        community: user.community,
        role: role,
      );
    }
    _upsert(user);
    _currentUser = user;
    _pendingName = null;
    _pendingEmail = null;
    _pendingCommunity = null;
    _pendingProfileImageBytes = null;
    _pendingPassword = null;
    notifyListeners();
    return user;
  }

  void _upsert(MockUser user) {
    final index = _users.indexWhere(
      (item) => item.id == user.id || item.email == user.email,
    );
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
  }

  void updateProfileImage(Uint8List? profileImageBytes) {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = MockUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      community: user.community,
      profileImageBytes: profileImageBytes,
      phone: user.phone,
      bio: user.bio,
      joinedAt: user.joinedAt,
      identityVerified: user.identityVerified,
    );
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index != -1) _users[index] = _currentUser!;
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String community,
    required String phone,
    required String bio,
  }) {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = MockUser(
      id: user.id,
      name: name.trim(),
      email: user.email,
      role: user.role,
      community: community.trim(),
      profileImageBytes: user.profileImageBytes,
      phone: phone.trim(),
      bio: bio.trim(),
      joinedAt: user.joinedAt,
      identityVerified: user.identityVerified,
    );
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index != -1) _users[index] = _currentUser!;
    notifyListeners();
  }

  void logout() {
    _api.clearSession();
    OwnerListingsStore.instance.resetSession();
    _currentUser = null;
    notifyListeners();
  }
}
