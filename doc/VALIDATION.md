# Validation report

Validated on 2026-08-31. This report covers the repository bootstrap and the
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
Android plugin testDebugUnitTest                     PASS (3 native tests)
flutter build apk --debug (example)                  PASS
Android device integration_test native bridge       PASS (1 test)
Android API 35 install/start/native initialization   PASS
Swift Package manifest resolution                    PASS
iOS xcodebuild build-for-testing                     PASS
iOS Simulator install/start/native SDK invocation    PASS
dart pub publish --dry-run (clean Git snapshot)      PASS
repository secret/placeholder scan                   PASS
```

The iOS build resolves `MSAL` `2.15.0` from the official Microsoft repository,
then compiles the Swift plugin, Runner, and XCTest bundle for both simulator
architectures. The check also uses a temporary checkout whose directory name
differs from the Dart package name, guarding against SwiftPM package-identity
coupling. CocoaPods is not part of the package or validation graph.

The Android aggregate `testDebugUnitTest` task also executes tests shipped
inside Flutter's `integration_test` module. Three of those upstream Mockito
tests fail on this Java/AGP environment before the plugin task completes. The
scoped plugin native test task passes, and the complete example APK builds.
This upstream test-runner incompatibility is not hidden as a plugin pass.

The example was also installed and started on a Pixel Tablet Android 15
emulator. With syntactically valid non-production identifiers, the official
MSAL native client initialized, cached-account lookup returned signed-out, and
the custom Flutter sign-in/sign-up screen rendered without an embedded WebView.
This proves device-level bridge wiring but is not a live-tenant authentication
claim.

## Environment and live-test boundaries

The iOS app was ad-hoc signed with the example's MSAL keychain entitlement,
installed, and started on an isolated iPhone 17 Pro simulator. With
syntactically valid non-production identifiers, the official MSAL native client
initialized, cached-account lookup returned signed-out, and the Flutter
sign-in/sign-up screen rendered. This proves the iOS runtime bridge and native
SDK invocation without claiming a live-tenant authentication result. Xcode does
not discover devices from this isolated device set as test destinations, so
XCTest execution remains a CI/release gate even though the XCTest bundle
compiles for both simulator architectures.

No external-tenant client ID, tenant subdomain, or test mailbox was supplied.
Therefore the end-to-end Email OTP flow has not yet been run against Microsoft
Entra External ID. A live Android and iOS smoke test is required before calling
this slice production-ready or publishing a prerelease.

Password authentication, required attributes, password reset, token retrieval,
MFA/strong-auth continuations, and system-browser fallback execution remain out
of this slice and are tracked in `doc/IMPLEMENTATION_PLAN.md`.
