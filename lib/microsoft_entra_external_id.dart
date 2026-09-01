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

  /// Starts native sign-in and requests tokens for [scopes].
  ///
  /// Pass [password] when the UI already collected it. If it is omitted and
  /// the tenant requires a password, MSAL returns [NativeAuthPasswordRequired]
  /// and the app can continue with [submitPassword].
  Future<NativeAuthState> signIn(
    String username, {
    String? password,
    List<String> scopes = const [],
  }) => _platform.signIn(
    _validateUsername(username),
    password: password == null ? null : _validatePassword(password),
    scopes: _normalizeScopes(scopes),
  );

  /// Convenience API for a custom email/username and password form.
  Future<NativeAuthState> signInWithPassword(
    String username,
    String password, {
    List<String> scopes = const [],
  }) => signIn(username, password: password, scopes: scopes);

  /// Starts native sign-up with optional [password] and tenant [attributes].
  Future<NativeAuthState> signUp(
    String username, {
    String? password,
    Map<String, String> attributes = const {},
  }) => _platform.signUp(
    _validateUsername(username),
    password: password == null ? null : _validatePassword(password),
    attributes: _normalizeAttributes(attributes),
  );

  /// Convenience API for a customized email/password sign-up form.
  Future<NativeAuthState> signUpWithPassword(
    String username,
    String password, {
    Map<String, String> attributes = const {},
  }) => signUp(username, password: password, attributes: attributes);

  /// Starts self-service password reset and signs in after completion.
  Future<NativeAuthState> resetPassword(
    String username, {
    List<String> scopes = const [],
  }) => _platform.resetPassword(
    _validateUsername(username),
    scopes: _normalizeScopes(scopes),
  );

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

  /// Submits a password to an in-progress native sign-in continuation.
  Future<NativeAuthState> submitPassword(
    NativeAuthPasswordRequired state,
    String password,
  ) => _platform.submitPassword(
    state.continuationId,
    _validatePassword(password),
  );

  /// Submits tenant-defined string attributes to an in-progress sign-up.
  Future<NativeAuthState> submitAttributes(
    NativeAuthAttributesRequired state,
    Map<String, String> attributes,
  ) => _platform.submitAttributes(
    state.continuationId,
    _normalizeAttributes(attributes, allowEmpty: false),
  );

  Future<NativeAuthState> resendCode(NativeAuthCodeRequired state) =>
      _platform.resendCode(state.continuationId);

  /// Acquires an access token silently through the native MSAL cache.
  ///
  /// MSAL refreshes an expired token automatically. Set [forceRefresh] to
  /// bypass a valid cached access token and request a new one. Refresh tokens
  /// never cross the native boundary into Dart.
  Future<NativeAuthState> getAccessToken({
    List<String> scopes = const [],
    bool forceRefresh = false,
  }) => _platform.getAccessToken(
    scopes: _normalizeScopes(scopes),
    forceRefresh: forceRefresh,
  );

  Future<NativeAuthState> signOut() => _platform.signOut();

  static String _validateUsername(String username) {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty.');
    }
    return normalized;
  }

  static String _validatePassword(String password) {
    if (password.isEmpty) {
      throw ArgumentError.value('', 'password', 'Must not be empty.');
    }
    return password;
  }

  static List<String> _normalizeScopes(List<String> scopes) {
    final normalized = <String>{};
    for (final scope in scopes) {
      final value = scope.trim();
      if (value.isEmpty) {
        throw ArgumentError.value(scopes, 'scopes', 'Must not contain blanks.');
      }
      normalized.add(value);
    }
    return List.unmodifiable(normalized);
  }

  static Map<String, String> _normalizeAttributes(
    Map<String, String> attributes, {
    bool allowEmpty = true,
  }) {
    if (!allowEmpty && attributes.isEmpty) {
      throw ArgumentError.value(attributes, 'attributes', 'Must not be empty.');
    }
    final normalized = <String, String>{};
    for (final MapEntry(:key, :value) in attributes.entries) {
      final name = key.trim();
      if (name.isEmpty) {
        throw ArgumentError.value(
          attributes,
          'attributes',
          'Attribute names must not be blank.',
        );
      }
      if (normalized.containsKey(name)) {
        throw ArgumentError.value(
          attributes,
          'attributes',
          'Attribute names must be unique after trimming.',
        );
      }
      normalized[name] = value;
    }
    return Map.unmodifiable(normalized);
  }
}
