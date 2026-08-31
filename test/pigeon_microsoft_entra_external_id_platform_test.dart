import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
import 'package:microsoft_entra_external_id/src/generated/native_auth_api.g.dart'
    as pigeon;
import 'package:microsoft_entra_external_id/src/pigeon_microsoft_entra_external_id_platform.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeNativeAuthHostApi extends pigeon.NativeAuthHostApi {
  FakeNativeAuthHostApi({required this.status, this.result});

  final pigeon.NativeSdkStatusMessage status;
  final pigeon.NativeAuthResultMessage? result;

  @override
  Future<pigeon.NativeSdkStatusMessage> getNativeSdkStatus() async => status;

  pigeon.NativeAuthResultMessage get _result =>
      result ??
      pigeon.NativeAuthResultMessage(
        type: pigeon.NativeAuthResultTypeMessage.signedOut,
      );

  @override
  Future<pigeon.NativeAuthResultMessage> initialize(
    pigeon.NativeAuthConfigurationMessage configuration,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> getCurrentAccount() async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> startSignIn(
    pigeon.NativeAuthSignInParametersMessage parameters,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> startSignUp(String username) async =>
      _result;

  @override
  Future<pigeon.NativeAuthResultMessage> submitCode(
    String continuationId,
    String code,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> submitPassword(
    String continuationId,
    String password,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> resendCode(
    String continuationId,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> getAccessToken(
    pigeon.NativeAuthAccessTokenParametersMessage parameters,
  ) async => _result;

  @override
  Future<pigeon.NativeAuthResultMessage> signOut() async => _result;
}

void main() {
  test('maps Android SDK status without exposing generated types', () async {
    final platform = PigeonMicrosoftEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        status: pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.android,
          linked: false,
        ),
      ),
    );

    expect(
      await platform.getNativeSdkStatus(),
      const NativeSdkStatus(platform: NativePlatform.android, linked: false),
    );
  });

  test('maps iOS SDK version when linked', () async {
    final platform = PigeonMicrosoftEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        status: pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.ios,
          linked: true,
          sdkVersion: 'test-version',
        ),
      ),
    );

    expect(
      await platform.getNativeSdkStatus(),
      const NativeSdkStatus(
        platform: NativePlatform.ios,
        linked: true,
        sdkVersion: 'test-version',
      ),
    );
  });

  test('maps an OTP continuation without exposing generated types', () async {
    final platform = PigeonMicrosoftEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        status: pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.android,
          linked: true,
        ),
        result: pigeon.NativeAuthResultMessage(
          type: pigeon.NativeAuthResultTypeMessage.codeRequired,
          operation: pigeon.NativeAuthOperationMessage.signIn,
          continuationId: 'opaque-id',
          sentTo: 'u***@example.com',
          codeLength: 6,
        ),
      ),
    );

    final state = await platform.signIn('user@example.com');

    expect(state, isA<NativeAuthCodeRequired>());
    final codeRequired = state as NativeAuthCodeRequired;
    expect(codeRequired.operation, NativeAuthOperation.signIn);
    expect(codeRequired.continuationId, 'opaque-id');
    expect(codeRequired.sentTo, 'u***@example.com');
    expect(codeRequired.codeLength, 6);
  });

  test(
    'maps a password continuation without exposing generated types',
    () async {
      final platform = PigeonMicrosoftEntraExternalIdPlatform(
        hostApi: FakeNativeAuthHostApi(
          status: pigeon.NativeSdkStatusMessage(
            platform: pigeon.NativePlatformMessage.ios,
            linked: true,
          ),
          result: pigeon.NativeAuthResultMessage(
            type: pigeon.NativeAuthResultTypeMessage.passwordRequired,
            operation: pigeon.NativeAuthOperationMessage.signIn,
            continuationId: 'password-id',
          ),
        ),
      );

      final state = await platform.signIn('user@example.com');

      expect(state, isA<NativeAuthPasswordRequired>());
      final passwordRequired = state as NativeAuthPasswordRequired;
      expect(passwordRequired.operation, NativeAuthOperation.signIn);
      expect(passwordRequired.continuationId, 'password-id');
    },
  );

  test('maps account, ID token, access token, scopes, and expiry', () async {
    final platform = PigeonMicrosoftEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        status: pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.android,
          linked: true,
        ),
        result: pigeon.NativeAuthResultMessage(
          type: pigeon.NativeAuthResultTypeMessage.signedIn,
          username: 'user@example.com',
          idToken: 'id-token',
          accessToken: 'access-token',
          scopes: const ['api://client/read'],
          expiresAtEpochMilliseconds: 1893456000000,
        ),
      ),
    );

    final state = await platform.getAccessToken(
      scopes: const ['api://client/read'],
    );

    expect(state, isA<NativeAuthSignedIn>());
    final signedIn = state as NativeAuthSignedIn;
    expect(signedIn.username, 'user@example.com');
    expect(signedIn.idToken, 'id-token');
    expect(signedIn.token.accessToken, 'access-token');
    expect(signedIn.token.scopes, const ['api://client/read']);
    expect(signedIn.token.expiresAt, DateTime.utc(2030));
  });

  test('maps browser-required as a typed failure', () async {
    final platform = PigeonMicrosoftEntraExternalIdPlatform(
      hostApi: FakeNativeAuthHostApi(
        status: pigeon.NativeSdkStatusMessage(
          platform: pigeon.NativePlatformMessage.ios,
          linked: true,
        ),
        result: pigeon.NativeAuthResultMessage(
          type: pigeon.NativeAuthResultTypeMessage.browserRequired,
          errorCode: 'browser_required',
          errorMessage: 'Continue in browser.',
        ),
      ),
    );

    final state = await platform.signUp('user@example.com');

    expect(state, isA<NativeAuthFailure>());
    final failure = state as NativeAuthFailure;
    expect(failure.browserRequired, isTrue);
    expect(failure.code, 'browser_required');
    expect(failure.message, 'Continue in browser.');
  });
}
