import '../microsoft_entra_external_id_platform_interface.dart';
import 'generated/native_auth_api.g.dart' as pigeon;
import 'native_auth_state.dart';
import 'native_sdk_status.dart';

/// Pigeon-backed implementation of the platform bridge.
final class PigeonMicrosoftEntraExternalIdPlatform
    extends MicrosoftEntraExternalIdPlatform {
  PigeonMicrosoftEntraExternalIdPlatform({pigeon.NativeAuthHostApi? hostApi})
    : _hostApi = hostApi ?? pigeon.NativeAuthHostApi();

  final pigeon.NativeAuthHostApi _hostApi;

  @override
  Future<NativeSdkStatus> getNativeSdkStatus() async {
    final message = await _hostApi.getNativeSdkStatus();
    return NativeSdkStatus(
      platform: switch (message.platform) {
        pigeon.NativePlatformMessage.android => NativePlatform.android,
        pigeon.NativePlatformMessage.ios => NativePlatform.ios,
      },
      linked: message.linked,
      sdkVersion: message.sdkVersion,
    );
  }

  @override
  Future<NativeAuthState> initialize(
    NativeAuthConfiguration configuration,
  ) async => _mapResult(
    await _hostApi.initialize(
      pigeon.NativeAuthConfigurationMessage(
        clientId: configuration.clientId,
        tenantSubdomain: configuration.tenantSubdomain,
      ),
    ),
  );

  @override
  Future<NativeAuthState> getCurrentAccount() async =>
      _mapResult(await _hostApi.getCurrentAccount());

  @override
  Future<NativeAuthState> signIn(
    String username, {
    String? password,
    List<String> scopes = const [],
  }) async => _mapResult(
    await _hostApi.startSignIn(
      pigeon.NativeAuthSignInParametersMessage(
        username: username,
        password: password,
        scopes: scopes,
      ),
    ),
  );

  @override
  Future<NativeAuthState> signUp(String username) async =>
      _mapResult(await _hostApi.startSignUp(username));

  @override
  Future<NativeAuthState> submitCode(
    String continuationId,
    String code,
  ) async => _mapResult(await _hostApi.submitCode(continuationId, code));

  @override
  Future<NativeAuthState> submitPassword(
    String continuationId,
    String password,
  ) async =>
      _mapResult(await _hostApi.submitPassword(continuationId, password));

  @override
  Future<NativeAuthState> resendCode(String continuationId) async =>
      _mapResult(await _hostApi.resendCode(continuationId));

  @override
  Future<NativeAuthState> getAccessToken({
    List<String> scopes = const [],
    bool forceRefresh = false,
  }) async => _mapResult(
    await _hostApi.getAccessToken(
      pigeon.NativeAuthAccessTokenParametersMessage(
        scopes: scopes,
        forceRefresh: forceRefresh,
      ),
    ),
  );

  @override
  Future<NativeAuthState> signOut() async =>
      _mapResult(await _hostApi.signOut());

  static NativeAuthState _mapResult(pigeon.NativeAuthResultMessage message) {
    return switch (message.type) {
      pigeon.NativeAuthResultTypeMessage.initialized =>
        const NativeAuthInitialized(),
      pigeon.NativeAuthResultTypeMessage.signedOut =>
        const NativeAuthSignedOut(),
      pigeon.NativeAuthResultTypeMessage.signedIn => NativeAuthSignedIn(
        account: NativeAuthAccount(
          username: message.username,
          idToken: message.idToken,
        ),
        token: NativeAuthToken(
          accessToken:
              message.accessToken ??
              (throw StateError(
                'Native signed-in result has no access token.',
              )),
          scopes: List.unmodifiable(message.scopes ?? const []),
          expiresAt: switch (message.expiresAtEpochMilliseconds) {
            final milliseconds? => DateTime.fromMillisecondsSinceEpoch(
              milliseconds,
              isUtc: true,
            ),
            null => null,
          },
        ),
      ),
      pigeon.NativeAuthResultTypeMessage.codeRequired => NativeAuthCodeRequired(
        operation: switch (message.operation) {
          pigeon.NativeAuthOperationMessage.signIn =>
            NativeAuthOperation.signIn,
          pigeon.NativeAuthOperationMessage.signUp =>
            NativeAuthOperation.signUp,
          null => throw StateError(
            'Native code-required result has no operation.',
          ),
        },
        continuationId:
            message.continuationId ??
            (throw StateError(
              'Native code-required result has no continuation.',
            )),
        sentTo: message.sentTo,
        codeLength: message.codeLength,
      ),
      pigeon.NativeAuthResultTypeMessage.passwordRequired =>
        NativeAuthPasswordRequired(
          operation: switch (message.operation) {
            pigeon.NativeAuthOperationMessage.signIn =>
              NativeAuthOperation.signIn,
            pigeon.NativeAuthOperationMessage.signUp =>
              NativeAuthOperation.signUp,
            null => throw StateError(
              'Native password-required result has no operation.',
            ),
          },
          continuationId:
              message.continuationId ??
              (throw StateError(
                'Native password-required result has no continuation.',
              )),
        ),
      pigeon.NativeAuthResultTypeMessage.error => NativeAuthFailure(
        code: message.errorCode ?? 'native_auth_error',
        message: message.errorMessage ?? 'Native authentication failed.',
        browserRequired: false,
      ),
      pigeon.NativeAuthResultTypeMessage.browserRequired => NativeAuthFailure(
        code: message.errorCode ?? 'browser_required',
        message:
            message.errorMessage ??
            'This authentication flow must continue in a browser.',
        browserRequired: true,
      ),
    };
  }
}
