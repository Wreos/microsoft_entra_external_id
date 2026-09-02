# Microsoft Entra External ID Native Authentication for Flutter

An unofficial Flutter plugin that connects Microsoft Entra External ID Native
Authentication to the official MSAL SDKs for Android and iOS.

Your Flutter app owns the sign-up and sign-in UI. MSAL runs the authentication
protocol and keeps the native token cache.

## Example

<p>
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-email-otp.png" width="155" alt="Email OTP">
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-password.png" width="155" alt="Email and password">
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-attributes.png" width="155" alt="Sign-up attributes">
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-password-reset.png" width="155" alt="Password reset">
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-more.png" width="155" alt="Browser fallback and API setup">
</p>

## What's included

- Android and iOS plugin implementations in Kotlin and Swift.
- A typed Pigeon channel between Dart and the native platforms.
- Exact MSAL Native Authentication SDK versions for Android and iOS.
- Swift Package Manager as the only iOS dependency integration path.
- Native initialization, cached-account lookup, password and Email OTP sign-in
  and sign-up, tenant-defined required/custom attributes, self-service password
  reset, code/password/attribute submission, token acquisition and refresh,
  automatic sign-in after sign-up or reset, and sign-out.
- A Flutter example that owns the full authentication UI.

Read [INTENT.md][intent] for scope and [the implementation plan][plan] for the
delivery sequence. [The stack guide][stack] lists the verified toolchain and
deployment floors. [The validation report][validation] records the evidence and
environment limits.

## Requirements

- Flutter 3.47 or newer and Dart 3.13.2 or newer;
- Android API 24 or newer, with a Java 17 build JDK;
- iOS 17 or newer and a current Xcode toolchain.

## Scope

This plugin supports **external tenants** in Microsoft Entra External ID. It
does not support workforce Entra ID, legacy Azure AD B2C compatibility, or
browser-only MSAL flows.

The host Flutter app owns the UI. The plugin exposes native authentication as
typed states and continuations.

On Android, the plugin uses Microsoft's `INativeAuthPublicClientApplication`,
created with `createNativeAuthPublicClientApplication(...)` as documented in
the official [Native Authentication tutorial][native-auth-android].
Browser-based MSAL and embedded WebViews are outside the core authentication
path.

On iOS, it uses `MSALNativeAuthPublicClientApplication` and its typed delegate
states, following Microsoft's [iOS Native Authentication quickstart][native-auth-ios].

## Quick start

```dart
import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';

final entra = MicrosoftEntraExternalId();
await entra.initialize(
  const NativeAuthConfiguration(
    clientId: 'application-client-id',
    tenantSubdomain: 'contoso',
    redirectUri: 'msauth.com.example.app://auth',
  ),
);

final state = await entra.signInWithPassword(
  'user@example.com',
  password,
  scopes: const ['api://your-api-client-id/access_as_user'],
);
if (state case final NativeAuthSignedIn signedIn) {
  final accessToken = signedIn.token.accessToken;
  final idToken = signedIn.idToken;
  // Send the access token only to its intended HTTPS API.
}
```

For a username-first UI, call `signIn(username)` without a password, then handle
`NativeAuthPasswordRequired` with `submitPassword(...)`. Email OTP uses
`NativeAuthCodeRequired` and `submitCode(...)`. Use `signUpWithPassword(...)`
for password sign-up. If the tenant requests profile data, render the returned
`NativeAuthAttributesRequired` fields and call `submitAttributes(...)`.
Password recovery begins with `resetPassword(...)` and uses the same typed code
and password states with `operation == NativeAuthOperation.passwordReset`.

MSAL owns the refresh token in its protected native cache. The plugin never
returns it to Dart. Acquire a cached token or let MSAL refresh an expired token
with `getAccessToken(scopes: ...)`; set `forceRefresh: true` only when the host
application explicitly needs to bypass a still-valid cached access token.

The [example][example] covers tenant prerequisites and run commands. Client ID
and tenant subdomain are public configuration values. Never put a client secret
in a mobile application, and do not log or persist passwords or returned tokens.

## Preview status

The current release is a development preview. Password and Email OTP sign-in,
password and Email OTP sign-up, required/custom attributes, password reset,
token retrieval/refresh, cached-account lookup, sign-out, and explicit browser
fallback are implemented on Android and iOS. MFA and strong-auth registration
are not implemented yet. The [validation report][validation] tracks platform
and tenant coverage.

## Browser fallback

When MSAL requires a flow to leave native authentication, the plugin returns
`NativeAuthFailure(browserRequired: true)`. This follows Microsoft's
[native-authentication web-fallback guidance][native-auth-web-fallback]. The
host can restart the flow in the system browser with the official MSAL client:

```dart
final result = await entra.signIn('user@example.com');
if (result case NativeAuthFailure(browserRequired: true)) {
  final browserResult = await entra.signInWithBrowser(
    loginHint: 'user@example.com',
    scopes: const ['openid', 'profile', 'email'],
  );
}
```

Register the platform redirect URI before using this method. On Android this
also requires the MSAL browser callback activity/intent filter in the host
application. On iOS, register `msauth.<bundle-id>://auth` and keep the MSAL
keychain group enabled. The browser path uses the system browser, never an
embedded WebView, and returns the same typed account and token result.

SDK initialization and runtime errors return a normal `NativeAuthFailure`. They
never silently switch authentication mechanisms.

## Contributing

Read [CONTRIBUTING.md][contributing] before opening an issue or pull request.
It covers the native-authentication boundary, local setup, Pigeon regeneration,
and required validation. All project spaces follow the [Code of Conduct][code-of-conduct].

Pull requests run package-scoped Dart formatting, analysis and unit tests,
generated Pigeon drift detection, Android plugin unit tests, iOS plugin-target
compilation, dependency review, and a pub.dev dry run. CI does not build or run
the example application. Device and live-tenant scenarios are manual release
gates. All third-party GitHub Actions are pinned to immutable commit SHAs and
updated through Dependabot.

A version tag that exactly matches `version` in `pubspec.yaml`, such as
`v0.1.0-dev.1`, reruns the full CI workflow and creates a draft GitHub
prerelease. Publishing that draft or publishing to pub.dev remains a manual
release decision until the live-tenant validation matrix is complete.

Security reports and the custom-UI trust boundary are documented in
[SECURITY.md][security] and the [security model][security-model]. API changes
before `1.0.0` follow the [migration policy][migration].

[native-auth-android]: https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app
[native-auth-ios]: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in
[native-auth-web-fallback]: https://learn.microsoft.com/en-us/entra/identity-platform/concept-native-authentication-web-fallback
[example]: https://github.com/Wreos/microsoft_entra_external_id/tree/main/example
[intent]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/INTENT.md
[plan]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/IMPLEMENTATION_PLAN.md
[stack]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/STACK.md
[validation]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/VALIDATION.md
[security]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/SECURITY.md
[security-model]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/SECURITY_MODEL.md
[migration]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/MIGRATION.md
[contributing]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/CONTRIBUTING.md
[code-of-conduct]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/CODE_OF_CONDUCT.md
