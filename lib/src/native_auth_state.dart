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
enum NativeAuthOperation { signIn, signUp }

/// Result of a native-authentication action.
sealed class NativeAuthState {
  const NativeAuthState();
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

/// A cached or newly authenticated account is available.
final class NativeAuthSignedIn extends NativeAuthState {
  const NativeAuthSignedIn({this.username});

  final String? username;
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
