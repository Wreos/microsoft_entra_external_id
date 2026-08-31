import 'microsoft_entra_external_id_platform_interface.dart';
import 'src/native_auth_state.dart';
import 'src/native_sdk_status.dart';

export 'src/native_auth_state.dart';
export 'src/native_sdk_status.dart';

/// Entry point for the Microsoft Entra External ID native authentication bridge.
///
class MicrosoftEntraExternalId {
  MicrosoftEntraExternalId({MicrosoftEntraExternalIdPlatform? platform})
    : _platform = platform ?? MicrosoftEntraExternalIdPlatform.instance;

  final MicrosoftEntraExternalIdPlatform _platform;

  /// Returns whether the official MSAL SDK is linked on the current platform.
  Future<NativeSdkStatus> getNativeSdkStatus() =>
      _platform.getNativeSdkStatus();

  /// Initializes the official native-authentication SDK for an external
  /// tenant. Call once before any account or interactive operation.
  Future<NativeAuthState> initialize(NativeAuthConfiguration configuration) {
    final clientId = configuration.clientId.trim();
    final tenantSubdomain = configuration.tenantSubdomain.trim();
    if (clientId.isEmpty) {
      throw ArgumentError.value(clientId, 'clientId', 'Must not be empty.');
    }
    if (tenantSubdomain.isEmpty ||
        tenantSubdomain.contains('.') ||
        tenantSubdomain.contains('/')) {
      throw ArgumentError.value(
        tenantSubdomain,
        'tenantSubdomain',
        'Use only the tenant prefix, for example "contoso".',
      );
    }
    return _platform.initialize(
      NativeAuthConfiguration(
        clientId: clientId,
        tenantSubdomain: tenantSubdomain,
      ),
    );
  }

  Future<NativeAuthState> getCurrentAccount() => _platform.getCurrentAccount();

  Future<NativeAuthState> signIn(String username) =>
      _platform.signIn(_validateUsername(username));

  Future<NativeAuthState> signUp(String username) =>
      _platform.signUp(_validateUsername(username));

  Future<NativeAuthState> submitCode(
    NativeAuthCodeRequired state,
    String code,
  ) {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', 'Must not be empty.');
    }
    return _platform.submitCode(state.continuationId, normalizedCode);
  }

  Future<NativeAuthState> resendCode(NativeAuthCodeRequired state) =>
      _platform.resendCode(state.continuationId);

  Future<NativeAuthState> signOut() => _platform.signOut();

  static String _validateUsername(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty.');
    }
    return normalized;
  }
}
