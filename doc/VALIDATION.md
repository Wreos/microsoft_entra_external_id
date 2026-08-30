# Validation report

Validated on 2026-08-30. This report covers the repository bootstrap and the
deterministic Email one-time-passcode implementation slice. It does not claim a
live-tenant result or production readiness.

## Environment

- Flutter `3.47.2` stable, framework revision `d3b14c8769`.
- Dart `3.13.2`; Pigeon `28.0.0`.
- Android Gradle Plugin `9.1.0`; Gradle `9.3.1`; Java `17.0.18`.
- Xcode `26.6`; Swift Package Manager only.
- MSAL Android `8.4.2`; MSAL iOS `2.15.0`.

## Implemented slice

- Official native-authentication clients on both platforms:
  `INativeAuthPublicClientApplication` on Android and
  `MSALNativeAuthPublicClientApplication` on iOS.
- Initialization from application client ID and external-tenant subdomain.
- Cached-account lookup.
- Email OTP sign-in and sign-up.
- Verification-code submission and resend.
- Automatic sign-in after sign-up.
- Sign-out and typed browser-required/error states.
- Custom Flutter example UI with no embedded WebView.
- SwiftPM-only iOS integration and MSAL keychain entitlement in the example.

## Deterministic gates

The final implementation snapshot passed:

```text
Pigeon regeneration + generated-output drift check   PASS
dart format                                           PASS
flutter analyze                                      PASS
flutter test                                         PASS (9 tests)
flutter test (example)                               PASS (2 widget tests)
Android plugin testDebugUnitTest                     PASS (1 native test)
flutter build apk --debug (example)                  PASS
Swift Package manifest resolution                    PASS
iOS xcodebuild build-for-testing                     PASS
dart pub publish --dry-run (clean Git snapshot)      PASS
repository secret/placeholder scan                   PASS
```

The iOS build resolves `MSAL` `2.15.0` from the official Microsoft repository,
then compiles the Swift plugin, Runner, and XCTest bundle for both simulator
architectures. CocoaPods is not part of the package or validation graph.

The Android aggregate `testDebugUnitTest` task also executes tests shipped
inside Flutter's `integration_test` module. Three of those upstream Mockito
tests fail on this Java/AGP environment before the plugin task completes. The
scoped plugin native test task passes, and the complete example APK builds.
This upstream test-runner incompatibility is not hidden as a plugin pass.

## Environment and live-test boundaries

`build-for-testing` passes, but this machine exposes no usable iOS Simulator
device, so XCTest execution cannot start locally. Simulator runtime tests remain
a CI/release gate.

No external-tenant client ID, tenant subdomain, or test mailbox was supplied.
Therefore the end-to-end Email OTP flow has not yet been run against Microsoft
Entra External ID. A live Android and iOS smoke test is required before calling
this slice production-ready or publishing a prerelease.

Password authentication, required attributes, password reset, token retrieval,
MFA/strong-auth continuations, and system-browser fallback execution remain out
of this slice and are tracked in `doc/IMPLEMENTATION_PLAN.md`.
