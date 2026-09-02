# Repository guidance

## Overview

`microsoft_entra_external_id` is an unofficial Flutter bridge to the official
Microsoft Entra External ID Native Authentication SDKs. Flutter owns the UI;
MSAL Android and MSAL iOS own the authentication protocol and native token
cache. The package targets external tenants only.

Do not replace native authentication with a Dart OAuth implementation, an
embedded WebView, or browser-first MSAL. A system-browser flow is a separate,
explicit fallback path.

## Naming

Keep the Microsoft prefix consistent across the package and platform layers:

- Dart package: `microsoft_entra_external_id`
- Dart entry point: `MicrosoftEntraExternalId`
- Android namespace: `io.github.wreos.microsoft_entra_external_id`
- Native plugin class: `MicrosoftEntraExternalIdPlugin`
- SwiftPM target: `microsoft_entra_external_id`

Do not reintroduce the former `entra_external_id` package or class names.

## Platform constraints

- Flutter 3.47+, Dart 3.13.2+, Android API 24+, Java 17, and iOS 17+.
- Pin MSAL versions exactly; do not use floating native dependency versions.
- Use Swift Package Manager for the iOS plugin dependency. Do not add a
  podspec or a CocoaPods fallback for this package.
- Keep one native client per Flutter plugin instance and release native state
  when the engine detaches.

## Current capabilities

The implemented flow is password and Email OTP sign-in, Email OTP sign-up,
verification-code/password submission, automatic sign-in after sign-up,
cached-account lookup, access/ID token retrieval, silent cache refresh, forced
access-token refresh, sign-out, and explicit system-browser fallback. MFA and
strong-auth registration are not implemented yet.

Refresh tokens stay inside the native MSAL cache and must never be added to the
Pigeon or Dart contracts. `getAccessToken(forceRefresh: false)` uses the cache
and refreshes expired access tokens; `forceRefresh: true` explicitly bypasses a
still-valid cached access token.

`NativeAuthFailure.browserRequired == true` is a signal to the host app. The
host can call `signInWithBrowser(...)` to restart the flow through the official
MSAL system-browser path. Ordinary SDK failures must not silently switch
authentication mechanisms.

## Generated code

Edit `pigeons/native_auth_api.dart`, then regenerate every language together:

```sh
dart run pigeon --input pigeons/native_auth_api.dart
dart format lib/src/generated/native_auth_api.g.dart
```

Never hand-edit generated Dart, Kotlin, or Swift channel files.

## Validation

Before committing implementation changes, run:

```sh
dart format --output=none --set-exit-if-changed \
  lib test pigeons example/lib example/test example/integration_test
flutter analyze --fatal-infos --fatal-warnings
flutter test
(cd example && flutter test)
```

Run the relevant native and device tests locally for platform changes. CI is
deliberately package-scoped: it tests the Dart plugin contract, the Android
plugin module, and compilation of the iOS plugin target. It does not build or
run the example application. For release work, run
`dart pub publish --dry-run` from a clean Git snapshot so rename/deletion state
cannot hide package-layout warnings.

## Security and tenant configuration

Never commit client secrets, OTP codes, passwords, tokens, continuation data,
tenant test accounts, or PII. Client ID and tenant subdomain are public mobile
configuration and should be supplied through app configuration such as
`--dart-define` in the example.

Keep passwords, OTPs, and continuation state in memory, clear UI controllers
after submission, and expose only sanitized errors. Do not log native SDK
result objects wholesale. Access and ID tokens may cross into Dart only as an
explicit authentication result and must never appear in diagnostics.

## Documentation and integration

Keep README capability claims aligned with both platform implementations and
the live-test matrix in `doc/VALIDATION.md`. Use
`.agents/skills/integrate-microsoft-entra-external-id` when integrating the
plugin into another Flutter application.
