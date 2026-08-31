import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native SDK status crosses the platform bridge', (
    WidgetTester tester,
  ) async {
    final MicrosoftEntraExternalId plugin = MicrosoftEntraExternalId();
    final status = await plugin.getNativeSdkStatus();

    expect(status.linked, isTrue);
    expect(status.sdkVersion, isNotEmpty);
  });
}
