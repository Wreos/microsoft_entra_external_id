## 0.2.0-dev.4

- Add an opt-in simulator integration test for configured iOS native-client
  initialization, including the MSAL internal-error regression path.

## 0.2.0-dev.3

- Fix iOS MSAL initialization for broker-capable redirect URIs by registering
  the required `msauthv2` and `msauthv3` query schemes in the example app.

## 0.2.0-dev.2

- Add explicit system-browser fallback through the native MSAL clients.
- Split the Flutter example into Email OTP, Password, Attributes, Password
  Reset, and More scenarios for easier testing and issue reproduction.
- Harden public input normalization and malformed native-result handling.
- Add live Android validation for password sign-in, token acquisition and
  refresh, sign-out, and cache state after process restart.

## 0.2.0-dev.1

- Add native password sign-up and tenant-defined required/custom attributes.
- Add self-service password reset with Email OTP, new password submission, and
  automatic sign-in through the native MSAL continuation.
- Expose typed `NativeAuthAttributesRequired` state and
  `NativeAuthOperation.passwordReset`.
- Extend the Flutter example and deterministic Android/iOS/Dart validation for
  the new flows.

## 0.1.0-dev.1

- Add native password sign-in, password continuations, ID/access-token results,
  requested scopes, expiry metadata, and MSAL cache refresh APIs.
- Keep refresh tokens exclusively in the protected native MSAL cache.
- Name the package and public/native plugin identifiers
  `microsoft_entra_external_id`.
- Bootstrap Android and iOS plugin structure from Flutter's official template.
- Define the product intent, initial scope boundaries, and gate-based implementation plan.
- Add a typed Pigeon native-authentication state machine.
- Link MSAL Android 8.4.2 and MSAL iOS 2.15.0 through Swift Package Manager.
- Implement cached-account lookup, Email OTP sign-in/sign-up, code
  submission/resend, automatic sign-in after sign-up, and sign-out.
- Add a working custom-Flutter-UI example with no embedded WebView.
- Add GitHub Actions gates for Dart, Android, iOS, generated code, package
  publishing, and draft GitHub releases, plus weekly dependency updates. CI is
  scoped to the plugin and does not build or run the example application.
