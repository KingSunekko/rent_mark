import 'package:flutter_test/flutter_test.dart';
import 'package:rent_mark/main.dart';

void main() {
  testWidgets('RentMark app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const RentMarkApp());

    expect(find.text('RentMark'), findsOneWidget);
  });
}
