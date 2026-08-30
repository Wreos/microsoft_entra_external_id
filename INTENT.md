---
status: bootstrap
date: 2026-08-30
package: entra_external_id
repository: entra_external_id
---

# Entra External ID for Flutter — Intent

## Product thesis

`entra_external_id` will be an unofficial Flutter plugin that bridges the official Microsoft Authentication Library (MSAL) Native Authentication SDKs for Android and iOS.

It will let Flutter applications build their own sign-up, sign-in, password-reset, and challenge UI while delegating authentication protocol handling, token caching, and platform-specific behavior to Microsoft's native SDKs.

The plugin is specifically for Microsoft Entra External ID external tenants. It is not a general Microsoft identity or workforce Entra ID plugin.

## Problem

Microsoft provides Native Authentication SDKs for Kotlin/Java and Swift/Objective-C, but no official Flutter integration. Existing Flutter MSAL plugins focus on browser-delegated authentication through a browser, embedded web view, or broker. Flutter teams that need a first-party, fully branded customer authentication UI must currently maintain their own Android and iOS bridges or call lower-level authentication APIs directly.

## Target users

- Flutter teams building customer-facing mobile applications on Entra External ID.
- Teams that require a branded in-app authentication experience for email/password or email one-time-passcode flows.
- Teams that prefer Microsoft-supported native protocol implementations over a custom Dart HTTP client.

## Core promise

Expose the native authentication flow as a typed Dart state machine. The host application owns presentation; the plugin owns the bridge to the native MSAL SDKs.

The plugin must never claim that every flow is browserless. It must surface browser fallback explicitly when Entra or a federated identity provider requires it.

## MVP scope

The first usable release targets Android and iOS and includes:

1. Native Auth client initialization with client ID, tenant subdomain, challenge types, capabilities, and optional redirect URI.
2. Sign-up with email/password and email one-time passcode.
3. Sign-in with email/password and email one-time passcode.
4. Verification-code submission and resend.
5. Required built-in and custom user attributes.
6. Self-service password reset.
7. Sign-in continuation after sign-up and password reset.
8. Current-account lookup, ID token access, access-token retrieval, refresh, and sign-out.
9. Typed errors with correlation IDs and safe diagnostic metadata.
10. Explicit MFA, strong-auth registration, and browser-fallback states, even if some continuations land after the first release.
11. A custom Flutter example application and platform integration tests.

## Public API direction

The public API will model native SDK continuation states rather than expose Kotlin or Swift implementation objects.

Expected state families include:

- completed
- code required
- password required
- attributes required
- MFA required
- strong-auth registration required
- browser fallback required
- failed

Continuation handles are opaque, short-lived, and in-memory only. Applications advance a flow through typed methods such as `submitCode`, `submitPassword`, `submitAttributes`, `resendCode`, or `cancel`.

## Architecture decisions

- **Native Authentication is a hard invariant.** On Android, create and retain
  `INativeAuthPublicClientApplication` through
  `PublicClientApplication.createNativeAuthPublicClientApplication(...)`, as
  defined by Microsoft's [External ID Native Authentication tutorial][native-auth-android].
  The iOS bridge must create `MSALNativeAuthPublicClientApplication` with
  `MSALNativeAuthPublicClientApplicationConfig` and map its delegate states, as
  demonstrated by Microsoft's [iOS Native Authentication quickstart][native-auth-ios].
  Ordinary browser-based MSAL interactive acquisition, embedded WebViews, and
  a custom Dart OAuth implementation are not acceptable substitutes.
- Start as one Flutter plugin package with in-package Android and iOS implementations. Revisit package-separated federation only after the public API stabilizes.
- Bootstrap with Flutter's official `plugin` template using Kotlin and Swift.
- Use Pigeon-generated channels for the production contract instead of handwritten map-based method channels.
- Keep engine-specific state on each plugin instance and release it when the Flutter engine detaches.
- Keep UI widgets out of the core package. The example app demonstrates custom UI; an optional UI companion package may be considered later.
- Depend on official Microsoft MSAL artifacts only. Do not reimplement the Native Authentication protocol in Dart for the MVP.

## Security constraints

- Never log passwords, one-time codes, continuation tokens, access tokens, ID tokens, or personally identifiable information.
- Never persist passwords, one-time codes, or continuation handles.
- Minimize credential lifetime and copies across the Dart/native boundary; clear Flutter controllers immediately after submission.
- Keep token caching in the native MSAL SDK. Return access tokens only when explicitly requested by the application.
- Preserve native correlation IDs while exposing only sanitized errors to Dart.
- Document the shared security responsibility introduced by custom native authentication UI.
- Provide a private security-reporting path before the first public release.

## Non-goals for MVP

- Workforce Entra ID authentication.
- Legacy Azure AD B2C compatibility guarantees.
- Web, macOS, Windows, or Linux implementations.
- A prebuilt production login UI or design system.
- Direct username/password OAuth flows implemented in Dart.
- Eliminating browser fallback or supporting social identity providers without browser handoff.
- Microsoft Graph client functionality beyond tokens required by the host application.

## Validation gates

Every implementation stage must pass its gate before the next stage starts:

1. **Intent gate:** scope and differentiation match official Microsoft and Flutter documentation.
2. **Bootstrap gate:** generated plugin matches Flutter's official Android/iOS plugin structure and contains no `com.example` identifiers.
3. **Contract gate:** the Dart model represents both Android result states and iOS delegate/state continuations without platform leakage.
4. **Android gate:** native unit tests cover every mapped result and continuation before a live-tenant smoke test.
5. **iOS gate:** native unit tests cover every mapped delegate callback and continuation before a live-tenant smoke test.
6. **Cross-platform gate:** the same Dart scenario tests pass against both native implementations.
7. **Security gate:** credential/token logging checks, dependency review, and documented threat model pass.
8. **Release gate:** formatting, static analysis, Dart tests, Android tests/build, iOS tests/build, example integration tests, and `flutter pub publish --dry-run` all pass.

## Bootstrap acceptance criteria

- The repository is initialized with Git.
- The package is named `entra_external_id` and supports only Android and iOS.
- Android uses Kotlin and an OSS-safe reverse-domain namespace.
- iOS uses Swift.
- The generated example, unit tests, and native test locations are retained.
- `dart format`, `flutter analyze`, and `flutter test` pass.
- The initial implementation plan is checked into the repository.
- No package is published and no API is presented as stable.

## Success criteria for the MVP

- One example External ID tenant completes password and email-OTP sign-up/sign-in on both Android and iOS.
- Password reset and token retrieval work on both platforms.
- At least one independent Flutter team can integrate the plugin without modifying native bridge code.
- No secret, credential, continuation token, or access token appears in logs or persisted plugin state.

## Open questions

- Which MFA and strong-auth registration states have stable parity across the current Android and iOS SDKs.
- Whether the first public release should expose browser fallback or return a typed unsupported result until the fallback bridge is implemented.
- Final package publisher and GitHub organization.

The bootstrap deployment floors are resolved as Android API 24 and iOS 17.
See `docs/STACK.md` for the selected toolchain and the reason for each floor.

[native-auth-android]: https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app
[native-auth-ios]: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in
