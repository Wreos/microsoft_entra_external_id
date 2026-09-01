/// Configuration for a Microsoft Entra External ID native-authentication
/// client.
final class NativeAuthConfiguration {
  const NativeAuthConfiguration({
    required this.clientId,
    required this.tenantSubdomain,
  });

  /// Application (client) ID from the external tenant app registration.
  final String clientId;

  /// Tenant prefix, for example `contoso` for `contoso.onmicrosoft.com`.
  final String tenantSubdomain;
}

/// Authentication operation associated with an interactive state.
enum NativeAuthOperation { signIn, signUp, passwordReset }

/// Result of a native-authentication action.
sealed class NativeAuthState {
  const NativeAuthState();
}

/// Account information returned by the native MSAL cache.
final class NativeAuthAccount {
  const NativeAuthAccount({this.username, this.idToken});

  final String? username;

  /// Raw OpenID Connect ID token for identifying the signed-in user.
  final String? idToken;
}

/// Access token acquired and refreshed by native MSAL.
final class NativeAuthToken {
  const NativeAuthToken({
    required this.accessToken,
    required this.scopes,
    this.expiresAt,
  });

  /// Raw OAuth access token. Keep it in memory and never log or persist it.
  final String accessToken;

  /// Scopes granted for [accessToken].
  final List<String> scopes;

  /// Local expiration timestamp reported by MSAL, when available.
  final DateTime? expiresAt;
}

/// The native client is initialized and ready.
final class NativeAuthInitialized extends NativeAuthState {
  const NativeAuthInitialized();
}

/// No account is present in the native MSAL token cache.
final class NativeAuthSignedOut extends NativeAuthState {
  const NativeAuthSignedOut();
}

/// A one-time passcode was sent and must be submitted to continue.
final class NativeAuthCodeRequired extends NativeAuthState {
  const NativeAuthCodeRequired({
    required this.operation,
    required this.continuationId,
    this.sentTo,
    this.codeLength,
  });

  final NativeAuthOperation operation;

  /// Opaque handle to native in-memory state. It is invalid after plugin
  /// detachment, process termination, or successful completion.
  final String continuationId;

  final String? sentTo;
  final int? codeLength;
}

/// A password must be submitted to continue a native authentication flow.
final class NativeAuthPasswordRequired extends NativeAuthState {
  const NativeAuthPasswordRequired({
    required this.operation,
    required this.continuationId,
  });

  final NativeAuthOperation operation;

  /// Opaque handle to native in-memory state. It must never be persisted.
  final String continuationId;
}

/// Metadata for an attribute requested by the external tenant.
final class NativeAuthRequiredAttribute {
  const NativeAuthRequiredAttribute({
    required this.name,
    required this.type,
    required this.required,
    this.regex,
  });

  /// Attribute key accepted by MSAL, including custom extension attributes.
  final String name;

  /// Native data type reported by MSAL, such as `string`.
  final String type;

  final bool required;

  /// Optional validation expression supplied by the tenant.
  final String? regex;
}

/// Tenant-defined attributes must be submitted to continue sign-up.
final class NativeAuthAttributesRequired extends NativeAuthState {
  const NativeAuthAttributesRequired({
    required this.continuationId,
    required this.requiredAttributes,
    this.invalidAttributeNames = const [],
  });

  /// Opaque handle to native in-memory state. It must never be persisted.
  final String continuationId;

  final List<NativeAuthRequiredAttribute> requiredAttributes;

  /// Attribute keys rejected by the previous submission, when available.
  final List<String> invalidAttributeNames;
}

/// A cached or newly authenticated account is available.
final class NativeAuthSignedIn extends NativeAuthState {
  const NativeAuthSignedIn({required this.account, required this.token});

  final NativeAuthAccount account;
  final NativeAuthToken token;

  String? get username => account.username;

  String? get idToken => account.idToken;
}

/// The native flow could not continue.
final class NativeAuthFailure extends NativeAuthState {
  const NativeAuthFailure({
    required this.code,
    required this.message,
    required this.browserRequired,
  });

  final String code;
  final String message;

  /// Whether Microsoft requires the host app to continue in a system browser.
  /// The plugin never opens an embedded WebView.
  final bool browserRequired;
}
