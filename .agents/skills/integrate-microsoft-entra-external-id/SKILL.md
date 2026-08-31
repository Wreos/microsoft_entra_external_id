---
name: integrate-microsoft-entra-external-id
description: Integrate the microsoft_entra_external_id Flutter plugin into an Android/iOS application that uses a Microsoft Entra External ID external tenant and custom native-authentication UI. Use for app setup, tenant configuration, password or Email OTP sign-in, access-token retrieval, and integration validation; do not use for workforce Entra ID or browser-only MSAL integrations.
---

# Integrate Microsoft Entra External ID

Preserve the host application's architecture and visual design. The plugin
provides typed authentication states, not UI widgets.

## Confirm fit

Before editing, confirm from the app and request that all of these are true:

- The tenant is a Microsoft Entra External ID external tenant.
- The target is Flutter on Android and/or iOS.
- The desired primary flow is custom-UI native authentication.
- Password or Email OTP native sign-in covers the application's sign-in need.

If the app requires workforce Entra ID, password sign-up, password reset,
required sign-up attributes, inline MFA, or automatic browser fallback,
explain that the package does not yet implement that path.
Do not hide the gap with a custom OAuth client or embedded WebView.

## Inspect before changing

Read the host `pubspec.yaml`, Android manifests and Gradle configuration, iOS
entitlements/project settings, and existing authentication code. Preserve
unrelated dependencies and any existing CocoaPods usage; this plugin itself is
integrated through Swift Package Manager and does not need a podspec.

Required floors are Flutter 3.47, Dart 3.13.2, Android API 24 with Java 17, and
iOS 17. Report a floor conflict before changing a host application's deployment
targets.

## Add the package

Use the published dependency requested by the user. For repository development,
use a path or Git dependency only when the user explicitly wants an unreleased
revision.

Import the public entry point:

```dart
import 'package:microsoft_entra_external_id/microsoft_entra_external_id.dart';
```

Do not import files under `lib/src`.

## Configure the external tenant

The app registration must allow public client flows and Native Authentication.
Associate it with an Email OTP or Email with password sign-up/sign-in user flow.
Supply only the application client ID and tenant subdomain; never create or
embed a client secret in a mobile app.

Treat the client ID and tenant subdomain as public configuration. Prefer the
host app's existing environment/configuration mechanism. Do not hardcode real
test accounts or tenant-specific credentials into source control.

## Platform setup

- Android: ensure the application manifest includes Internet permission.
- iOS: enable Swift Package Manager support and add the MSAL keychain group
  `$(AppIdentifierPrefix)com.microsoft.adalcache` to the Runner entitlements.
- Do not add redirect handlers for a browser flow unless that browser flow is
  being implemented and validated separately.

Use the repository example as the source of truth for the current platform
configuration.

## Wire the custom UI

Create one `MicrosoftEntraExternalId` instance and initialize it before account
or interactive operations. Drive the host UI from the sealed states:

- `NativeAuthSignedOut`: show sign-in and sign-up entry points.
- `NativeAuthCodeRequired`: show the OTP input and resend action.
- `NativeAuthPasswordRequired`: show a secure password input and submit it.
- `NativeAuthSignedIn`: use its account, ID token, and access token metadata.
- `NativeAuthFailure`: show a safe error and offer a retry.

For a combined form, use `signInWithPassword(username, password, scopes: ...)`.
For a username-first form, use `signIn(username, scopes: ...)`, then pass a
returned `NativeAuthPasswordRequired` to `submitPassword`. Pass
`NativeAuthCodeRequired` to `submitCode` or `resendCode`. Do not persist either
continuation identifier, and clear password/OTP controllers immediately after
submission.

Request API scopes explicitly. Use `NativeAuthSignedIn.token.accessToken` only
for the intended HTTPS resource. Call `getAccessToken(scopes: ...)` for silent
cache retrieval and automatic expiry refresh, or add `forceRefresh: true` to
bypass a valid cached access token. Never request, expose, log, or persist the
refresh token; MSAL owns it in the platform cache.

When `browserRequired` is true, stop the native flow and hand control to the
host application's explicitly configured system-browser authentication path.
The plugin does not open that browser automatically. A normal SDK failure with
`browserRequired == false` should remain an error/retry state.

## Validate

Run formatting, fatal analysis, widget tests, and the app's existing native or
integration tests. Validate password and OTP sign-in, code resend/submission,
restored account, API-scoped token acquisition/refresh, and sign-out on every
changed platform. Use a real external tenant only through runtime
configuration, and inspect logs for passwords, OTPs, tokens, continuations, and
PII before declaring the integration complete.
