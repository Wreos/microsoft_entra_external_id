import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
import 'package:microsoft_entra_external_id/microsoft_entra_external_id_platform_interface.dart';
import 'package:microsoft_entra_external_id/src/pigeon_microsoft_entra_external_id_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMicrosoftEntraExternalIdPlatform
    with MockPlatformInterfaceMixin
    implements MicrosoftEntraExternalIdPlatform {
  NativeAuthConfiguration? initializedWith;
  String? signedInUsername;
  String? signedUpUsername;
  String? submittedContinuationId;
  String? submittedCode;
  String? resentContinuationId;

  @override
  Future<NativeSdkStatus> getNativeSdkStatus() async => const NativeSdkStatus(
    platform: NativePlatform.android,
    linked: true,
    sdkVersion: 'test-version',
  );

  @override
  Future<NativeAuthState> initialize(
    NativeAuthConfiguration configuration,
  ) async {
    initializedWith = configuration;
    return const NativeAuthInitialized();
  }

  @override
  Future<NativeAuthState> getCurrentAccount() async =>
      const NativeAuthSignedOut();

  @override
  Future<NativeAuthState> signIn(String username) async {
    signedInUsername = username;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> signUp(String username) async {
    signedUpUsername = username;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> submitCode(String continuationId, String code) async {
    submittedContinuationId = continuationId;
    submittedCode = code;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> resendCode(String continuationId) async {
    resentContinuationId = continuationId;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> signOut() async => const NativeAuthSignedOut();
}

void main() {
  test('$PigeonMicrosoftEntraExternalIdPlatform is the default instance', () {
    expect(
      MicrosoftEntraExternalIdPlatform.instance,
      isInstanceOf<PigeonMicrosoftEntraExternalIdPlatform>(),
    );
  });

  test('getNativeSdkStatus delegates to the platform implementation', () async {
    final fakePlatform = MockMicrosoftEntraExternalIdPlatform();
    final plugin = MicrosoftEntraExternalId(platform: fakePlatform);

    expect(
      await plugin.getNativeSdkStatus(),
      const NativeSdkStatus(
        platform: NativePlatform.android,
        linked: true,
        sdkVersion: 'test-version',
      ),
    );
  });

  test('initialize trims and delegates public configuration', () async {
    final fakePlatform = MockMicrosoftEntraExternalIdPlatform();
    final plugin = MicrosoftEntraExternalId(platform: fakePlatform);

    expect(
      await plugin.initialize(
        const NativeAuthConfiguration(
          clientId: ' client-id ',
          tenantSubdomain: ' contoso ',
        ),
      ),
      isA<NativeAuthInitialized>(),
    );
    expect(fakePlatform.initializedWith?.clientId, 'client-id');
    expect(fakePlatform.initializedWith?.tenantSubdomain, 'contoso');
  });

  test('initialize rejects a tenant domain instead of a subdomain', () {
    final plugin = MicrosoftEntraExternalId(
      platform: MockMicrosoftEntraExternalIdPlatform(),
    );

    expect(
      () => plugin.initialize(
        const NativeAuthConfiguration(
          clientId: 'client-id',
          tenantSubdomain: 'contoso.onmicrosoft.com',
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'interactive operations normalize input and preserve continuation',
    () async {
      final fakePlatform = MockMicrosoftEntraExternalIdPlatform();
      final plugin = MicrosoftEntraExternalId(platform: fakePlatform);
      const state = NativeAuthCodeRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'continuation-id',
      );

      await plugin.signIn(' user@example.com ');
      await plugin.signUp(' new@example.com ');
      await plugin.submitCode(state, ' 123456 ');
      await plugin.resendCode(state);

      expect(fakePlatform.signedInUsername, 'user@example.com');
      expect(fakePlatform.signedUpUsername, 'new@example.com');
      expect(fakePlatform.submittedContinuationId, 'continuation-id');
      expect(fakePlatform.submittedCode, '123456');
      expect(fakePlatform.resentContinuationId, 'continuation-id');
    },
  );
}
