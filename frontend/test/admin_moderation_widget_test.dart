import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rent_mark/models/user_role.dart';
import 'package:rent_mark/screens/admin_dashboard_screen.dart';
import 'package:rent_mark/services/admin_api_service.dart';
import 'package:rent_mark/state/admin_state.dart';

class _FakeAdminApi extends AdminApiService {
  bool moderated = false;

  @override
  Future<AdminSnapshot> dashboard(String token) async => AdminSnapshot(
    const [
      MockUser(
        id: 'renter-1',
        name: 'Test Renter',
        email: 'renter@example.com',
        role: UserRole.renter,
        community: 'Digos City',
      ),
    ],
    const [],
    const [],
    const [],
    const {},
    const {},
  );

  @override
  Future<void> moderateUser(
    String token,
    String id,
    bool suspended,
    String reason,
  ) async {
    moderated = suspended;
  }
}

void main() {
  testWidgets('suspending a user closes the dialog without a framework error', (
    tester,
  ) async {
    final api = _FakeAdminApi();
    final state = AdminState(api: api)
      ..configureSession('admin-token', UserRole.admin);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: AdminDashboardScreen(adminName: 'Administrator'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.people_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUSPEND'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Policy violation');
    await tester.tap(find.widgetWithText(FilledButton, 'SUSPEND'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.moderated, isTrue);
    expect(find.text('RESTORE'), findsOneWidget);
  });
}
