import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/models/user_role.dart';
import 'package:rent_mark/services/auth_api_service.dart';
import 'package:rent_mark/state/auth_state.dart';

class _FakeAuthApi extends AuthApiService {
  int loginCalls = 0;
  int updateCalls = 0;

  @override
  Future<MockUser> login(String email, String password) async {
    loginCalls++;
    accessToken = 'server-token';
    return MockUser(
      id: 'server-user',
      name: 'Server User',
      email: email,
      role: UserRole.renter,
      community: 'Davao',
    );
  }

  @override
  Future<MockUser> updateProfile({
    required String name,
    required String community,
    required String phone,
    required String bio,
  }) async {
    updateCalls++;
    return MockUser(
      id: 'server-user',
      name: name,
      email: 'renter@example.com',
      role: UserRole.renter,
      community: community,
      phone: phone,
      bio: bio,
    );
  }
}

void main() {
  test('login always uses the backend authentication service', () async {
    final api = _FakeAuthApi();
    final state = AuthState(api: api);

    final user = await state.login('renter@example.com', 'real-password');

    expect(api.loginCalls, 1);
    expect(state.accessToken, 'server-token');
    expect(user.id, 'server-user');
  });

  test(
    'profile edits use and retain the authoritative backend response',
    () async {
      final api = _FakeAuthApi();
      final state = AuthState(api: api);
      await state.login('renter@example.com', 'real-password');

      state.updateProfile(
        name: 'Updated Name',
        community: 'Digos',
        phone: '09123456789',
        bio: 'Updated remotely',
      );

      expect(api.updateCalls, 1);
      expect(state.currentUser?.name, 'Updated Name');
      expect(state.currentUser?.community, 'Digos');
    },
  );
}
