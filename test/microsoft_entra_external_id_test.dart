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
  String? signedInPassword;
  List<String>? signedInScopes;
  String? signedUpUsername;
  String? signedUpPassword;
  Map<String, String>? signedUpAttributes;
  String? resetPasswordUsername;
  List<String>? resetPasswordScopes;
  String? browserLoginHint;
  List<String>? browserScopes;
  String? submittedContinuationId;
  String? submittedCode;
  String? submittedPassword;
  Map<String, String>? submittedAttributes;
  String? resentContinuationId;
  List<String>? requestedTokenScopes;
  bool? requestedForceRefresh;

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
  Future<NativeAuthState> signIn(
    String username, {
    String? password,
    List<String> scopes = const [],
  }) async {
    signedInUsername = username;
    signedInPassword = password;
    signedInScopes = scopes;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> signUp(
    String username, {
    String? password,
    Map<String, String> attributes = const {},
  }) async {
    signedUpUsername = username;
    signedUpPassword = password;
    signedUpAttributes = attributes;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> resetPassword(
    String username, {
    List<String> scopes = const [],
  }) async {
    resetPasswordUsername = username;
    resetPasswordScopes = scopes;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> signInWithBrowser({
    String? loginHint,
    List<String> scopes = const [],
  }) async {
    browserLoginHint = loginHint;
    browserScopes = scopes;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> submitCode(String continuationId, String code) async {
    submittedContinuationId = continuationId;
    submittedCode = code;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> submitPassword(
    String continuationId,
    String password,
  ) async {
    submittedContinuationId = continuationId;
    submittedPassword = password;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> submitAttributes(
    String continuationId,
    Map<String, String> attributes,
  ) async {
    submittedContinuationId = continuationId;
    submittedAttributes = attributes;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> resendCode(String continuationId) async {
    resentContinuationId = continuationId;
    return const NativeAuthSignedOut();
  }

  @override
  Future<NativeAuthState> getAccessToken({
    List<String> scopes = const [],
    bool forceRefresh = false,
  }) async {
    requestedTokenScopes = scopes;
    requestedForceRefresh = forceRefresh;
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

  test('browser fallback normalizes login hint and scopes', () async {
    final fakePlatform = MockMicrosoftEntraExternalIdPlatform();
    final plugin = MicrosoftEntraExternalId(platform: fakePlatform);

    await plugin.signInWithBrowser(
      loginHint: ' user@example.com ',
      scopes: const [' openid ', 'profile', 'openid'],
    );

    expect(fakePlatform.browserLoginHint, 'user@example.com');
    expect(fakePlatform.browserScopes, const ['openid', 'profile']);
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
      const passwordState = NativeAuthPasswordRequired(
        operation: NativeAuthOperation.signIn,
        continuationId: 'password-continuation-id',
      );
      const attributesState = NativeAuthAttributesRequired(
        continuationId: 'attributes-continuation-id',
        requiredAttributes: [
          NativeAuthRequiredAttribute(
            name: 'displayName',
            type: 'string',
            required: true,
          ),
        ],
      );

      await plugin.signInWithPassword(
        ' user@example.com ',
        ' secret password ',
        scopes: const [' api://client/read ', 'api://client/read'],
      );
      await plugin.signUpWithPassword(
        ' new@example.com ',
        ' new secret ',
        attributes: const {' displayName ': 'Aleksandr'},
      );
      await plugin.resetPassword(
        ' recover@example.com ',
        scopes: const [' api://client/read ', 'api://client/read'],
      );
      await plugin.submitCode(state, ' 123456 ');
      await plugin.submitPassword(passwordState, 'secret password');
      await plugin.submitAttributes(attributesState, const {
        ' displayName ': 'Aleksandr',
      });
      await plugin.resendCode(state);
      await plugin.getAccessToken(
        scopes: const [' api://client/write '],
        forceRefresh: true,
      );

      expect(fakePlatform.signedInUsername, 'user@example.com');
      expect(fakePlatform.signedInPassword, ' secret password ');
      expect(fakePlatform.signedInScopes, const ['api://client/read']);
      expect(fakePlatform.signedUpUsername, 'new@example.com');
      expect(fakePlatform.signedUpPassword, ' new secret ');
      expect(fakePlatform.signedUpAttributes, const {
        'displayName': 'Aleksandr',
      });
      expect(fakePlatform.resetPasswordUsername, 'recover@example.com');
      expect(fakePlatform.resetPasswordScopes, const ['api://client/read']);
      expect(
        fakePlatform.submittedContinuationId,
        'attributes-continuation-id',
      );
      expect(fakePlatform.submittedCode, '123456');
      expect(fakePlatform.submittedPassword, 'secret password');
      expect(fakePlatform.submittedAttributes, const {
        'displayName': 'Aleksandr',
      });
      expect(fakePlatform.resentContinuationId, 'continuation-id');
      expect(fakePlatform.requestedTokenScopes, const ['api://client/write']);
      expect(fakePlatform.requestedForceRefresh, isTrue);
    },
  );

  test('rejects empty passwords and blank scopes before native calls', () {
    final plugin = MicrosoftEntraExternalId(
      platform: MockMicrosoftEntraExternalIdPlatform(),
    );

    expect(
      () => plugin.signInWithPassword('user@example.com', ''),
      throwsArgumentError,
    );
    expect(
      () => plugin.getAccessToken(scopes: const [' ']),
      throwsArgumentError,
    );
    expect(
      () => plugin.signUp('user@example.com', attributes: const {' ': 'value'}),
      throwsArgumentError,
    );
    expect(
      () => plugin.submitAttributes(
        const NativeAuthAttributesRequired(
          continuationId: 'continuation-id',
          requiredAttributes: [],
        ),
        const {},
      ),
      throwsArgumentError,
    );
  });

  test('rejects blank configuration and interactive values', () {
    final plugin = MicrosoftEntraExternalId(
      platform: MockMicrosoftEntraExternalIdPlatform(),
    );
    const codeState = NativeAuthCodeRequired(
      operation: NativeAuthOperation.signIn,
      continuationId: 'continuation-id',
    );

    expect(
      () => plugin.initialize(
        const NativeAuthConfiguration(
          clientId: ' ',
          tenantSubdomain: 'contoso',
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => plugin.initialize(
        const NativeAuthConfiguration(
          clientId: 'client-id',
          tenantSubdomain: ' ',
        ),
      ),
      throwsArgumentError,
    );
    expect(() => plugin.signIn(' '), throwsArgumentError);
    expect(() => plugin.signUp(' '), throwsArgumentError);
    expect(() => plugin.resetPassword(' '), throwsArgumentError);
    expect(() => plugin.submitCode(codeState, ' '), throwsArgumentError);
  });

  test('rejects attribute names that collide after trimming', () {
    final plugin = MicrosoftEntraExternalId(
      platform: MockMicrosoftEntraExternalIdPlatform(),
    );

    expect(
      () => plugin.signUp(
        'user@example.com',
        attributes: const {
          'displayName': 'First value',
          ' displayName ': 'Second value',
        },
      ),
      throwsArgumentError,
    );
  });

  test('delegates immutable normalized collections', () async {
    final fakePlatform = MockMicrosoftEntraExternalIdPlatform();
    final plugin = MicrosoftEntraExternalId(platform: fakePlatform);

    await plugin.signIn(
      'user@example.com',
      scopes: const [' openid ', 'openid', ' profile '],
    );
    await plugin.signUp(
      'user@example.com',
      attributes: const {' displayName ': 'Aleksandr'},
    );

    expect(fakePlatform.signedInScopes, const ['openid', 'profile']);
    expect(
      () => fakePlatform.signedInScopes!.add('email'),
      throwsUnsupportedError,
    );
    expect(fakePlatform.signedUpAttributes, const {'displayName': 'Aleksandr'});
    expect(
      () => fakePlatform.signedUpAttributes!['city'] = 'Berlin',
      throwsUnsupportedError,
    );
  });
}
