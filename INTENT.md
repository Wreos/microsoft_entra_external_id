---
status: active
package: microsoft_entra_external_id
repository: microsoft_entra_external_id
---

# Microsoft Entra External ID for Flutter

`microsoft_entra_external_id` is an unofficial Flutter bridge to Microsoft's
Native Authentication SDKs for Android and iOS. Flutter owns the UI. MSAL owns
the authentication protocol, native account state, token cache, and refresh
tokens.

## Scope

The package supports Microsoft Entra External ID external tenants. It provides
Email OTP and password sign-in and sign-up, required attributes, password reset,
typed continuations, account lookup, token retrieval and refresh, sign-out, and
explicit system-browser fallback.

It does not support workforce Entra ID, Azure AD B2C compatibility, Web, desktop
platforms, a prebuilt login UI, Microsoft Graph, embedded WebViews, or a Dart
OAuth implementation. MFA, strong-auth registration, and process-recreation
recovery are not implemented.

## Design rules

- Keep the public API as typed Dart states. Do not expose MSAL objects.
- Use `INativeAuthPublicClientApplication` on Android and
  `MSALNativeAuthPublicClientApplication` on iOS.
- Generate platform channels from `pigeons/native_auth_api.dart` with Pigeon.
- Keep each native client and its continuations within one plugin instance.
- Keep refresh tokens in MSAL's native cache. Never expose, log, or persist
  passwords, codes, continuation values, access tokens, ID tokens, or PII.
- Treat browser fallback as an explicit host action. Native failures must not
  switch to browser authentication automatically.

## Release baseline

The package targets Flutter 3.47+, Dart 3.13.2+, Android API 24 with Java 17,
and iOS 17+. Native MSAL versions are pinned exactly. iOS uses Swift Package
Manager only.

Release work requires formatting, fatal analysis, Dart and native tests, a
runnable example, a clean-snapshot `dart pub publish --dry-run`, and live
platform checks appropriate to the changed flow.

## Roadmap

The next work covers MFA, strong-auth registration, lifecycle and cancellation
semantics, and wider live-tenant coverage. Any new native state must have a
matching typed Dart state and tests on both platforms.
