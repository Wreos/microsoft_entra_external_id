import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';

const _clientId = String.fromEnvironment('ENTRA_CLIENT_ID');
const _tenantSubdomain = String.fromEnvironment('ENTRA_TENANT_SUBDOMAIN');
const _redirectUri = String.fromEnvironment('ENTRA_REDIRECT_URI');
final _hasTenantConfiguration =
    _clientId.isNotEmpty && _tenantSubdomain.isNotEmpty;

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

  testWidgets(
    'configured native client initializes without an MSAL internal error',
    (WidgetTester tester) async {
      expect(
        _hasTenantConfiguration,
        isTrue,
        reason:
            'Run this release smoke test with ENTRA_CLIENT_ID and '
            'ENTRA_TENANT_SUBDOMAIN dart-defines.',
      );

      final plugin = MicrosoftEntraExternalId();
      final state = await plugin.initialize(
        const NativeAuthConfiguration(
          clientId: _clientId,
          tenantSubdomain: _tenantSubdomain,
          redirectUri: _redirectUri,
        ),
      );

      expect(
        state,
        isNot(
          isA<NativeAuthFailure>().having(
            (failure) => failure.code,
            'code',
            'MSALErrorDomain/-50000',
          ),
        ),
      );
      expect(state, isNot(isA<NativeAuthFailure>()));
    },
  );
}
