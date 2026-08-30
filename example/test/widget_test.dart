import 'package:flutter_test/flutter_test.dart';

import 'package:entra_external_id_example/main.dart';

void main() {
  testWidgets('shows the native bridge bootstrap state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Checking native bridge...'), findsOneWidget);
  });
}
