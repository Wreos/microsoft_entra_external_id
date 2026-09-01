# Microsoft Entra External ID for Flutter

An unofficial Flutter plugin for Microsoft Entra External ID Native
Authentication, backed by the official MSAL Android and iOS SDKs.

It lets Flutter applications build fully custom sign-up and sign-in experiences
while MSAL handles the authentication protocol, native token cache, and
platform-specific behavior. Native-supported flows do not use an embedded
WebView.

## Custom Flutter UI, native authentication

![Successful Microsoft Entra External ID native sign-in on Android](https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/android-authenticated.png)

The screenshot shows a real Email OTP sign-in against an External ID tenant on
an Android device. The account identifier is redacted.

## What the plugin enables

- a Flutter plugin for Android and iOS, implemented in Kotlin and Swift;
- a typed Pigeon channel shared by Dart and the native platforms;
- exact native SDK pins: MSAL Android `8.4.2` and MSAL iOS `2.15.0`;
- Swift Package Manager as the only iOS dependency integration path;
- native initialization, cached-account lookup, password and Email OTP sign-in,
  password and Email OTP sign-up, tenant-defined required/custom attributes,
  self-service password reset, code/password/attribute submission, token
  acquisition/refresh, automatic sign-in after sign-up/reset, and sign-out;
- an example whose Flutter widgets own the complete authentication UI, with no
  embedded WebView.

Read [INTENT.md][intent] for product scope and [the implementation plan][plan]
for the execution sequence. The verified toolchain and deployment floors are
recorded in [the stack guide][stack], and the exact evidence and environment
limitations are recorded in [the validation report][validation].

## Requirements

- Flutter 3.47 or newer and Dart 3.13.2 or newer;
- Android API 24 or newer, with a Java 17 build JDK;
- iOS 17 or newer and a current Xcode toolchain.

## Scope

This plugin targets **external tenants** in Microsoft Entra External ID. It is
not intended for workforce Entra ID, legacy Azure AD B2C compatibility, or
browser-only MSAL flows.

The host Flutter app owns the UI. The plugin exposes native authentication as
typed states and continuations.

On Android, the implementation target is Microsoft's
`INativeAuthPublicClientApplication`, created with
`createNativeAuthPublicClientApplication(...)` as documented in the official
[Native Authentication tutorial][native-auth-android]. Browser-based MSAL and
embedded WebViews are not the core authentication path.

On iOS, the corresponding implementation target is
`MSALNativeAuthPublicClientApplication` plus its typed delegate states, following
Microsoft's [iOS Native Authentication quickstart][native-auth-ios].

## Quick start

```dart
import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';

final entra = MicrosoftEntraExternalId();
await entra.initialize(
  const NativeAuthConfiguration(
    clientId: 'application-client-id',
    tenantSubdomain: 'contoso',
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

For a username-first UI, call `signIn(username)` without a password and handle
`NativeAuthPasswordRequired` with `submitPassword(...)`. Email OTP continues to
use `NativeAuthCodeRequired` and `submitCode(...)`. Password sign-up uses
`signUpWithPassword(...)`; if the tenant requests profile data, render the
returned `NativeAuthAttributesRequired` fields and call `submitAttributes(...)`.
Password recovery starts with `resetPassword(...)` and uses the same typed code
and password states, with `operation == NativeAuthOperation.passwordReset`.

MSAL owns the refresh token in its protected native cache. The plugin never
returns it to Dart. Acquire a cached token or let MSAL refresh an expired token
with `getAccessToken(scopes: ...)`; set `forceRefresh: true` only when the host
application explicitly needs to bypass a still-valid cached access token.

See the [working example][example] for tenant prerequisites and run commands.
Client ID and tenant subdomain are public configuration values; never put
client secrets in a mobile application. Passwords and returned tokens must not
be logged or persisted by the host application.

## Development status

The current release is a development preview. Password and Email OTP sign-in,
password and Email OTP sign-up, required/custom attributes, password reset,
token retrieval/refresh, cached-account lookup, and sign-out are implemented on
Android and iOS. MFA, strong-auth registration, and browser-fallback execution
remain explicit follow-up work. Maintainers track platform and tenant coverage
in the [validation report][validation].

## Browser fallback

The plugin does not open a browser automatically. When MSAL determines that a
flow must leave native authentication, the plugin returns
`NativeAuthFailure(browserRequired: true)`. The host application must then
start its own system-browser authentication flow.

An SDK initialization or runtime error is returned as a normal
`NativeAuthFailure`; it does not silently switch authentication mechanisms.
Embedded WebViews are never used as a fallback.

## Contributing

Before implementing a new flow, update its contract tests and pass the
validation gate defined in the implementation plan.

Pull requests run package-scoped Dart formatting, analysis and unit tests,
generated Pigeon drift detection, Android plugin unit tests, iOS plugin-target
compilation, dependency review, and a pub.dev dry run. CI deliberately does not
build or run the example application. Device and live-tenant scenarios remain
manual release gates. All third-party GitHub Actions are pinned to immutable
commit SHAs and updated through Dependabot.

Pushing a version tag that exactly matches `version` in `pubspec.yaml` (for
example, `v0.1.0-dev.1`) reruns the complete CI workflow and creates a draft
GitHub prerelease. Publishing the draft or publishing to pub.dev remains a
deliberate manual release decision until the live-tenant validation matrix is
complete.

Security reports and the custom-UI trust boundary are documented in
[SECURITY.md][security] and the [security model][security-model]. API changes
before `1.0.0` follow the [migration policy][migration].

[native-auth-android]: https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app
[native-auth-ios]: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in
[example]: https://github.com/Wreos/microsoft_entra_external_id/tree/main/example
[intent]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/INTENT.md
[plan]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/IMPLEMENTATION_PLAN.md
[stack]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/STACK.md
[validation]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/VALIDATION.md
[security]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/SECURITY.md
[security-model]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/SECURITY_MODEL.md
[migration]: https://github.com/Wreos/microsoft_entra_external_id/blob/main/doc/MIGRATION.md
