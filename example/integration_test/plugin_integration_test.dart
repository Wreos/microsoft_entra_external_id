import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:entra_external_id/entra_external_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native SDK status crosses the platform bridge', (
    WidgetTester tester,
  ) async {
    final EntraExternalId plugin = EntraExternalId();
    final status = await plugin.getNativeSdkStatus();

    expect(status.linked, isFalse);
    expect(status.sdkVersion, isNull);
  });
}
