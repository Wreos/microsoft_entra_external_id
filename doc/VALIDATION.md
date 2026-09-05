# Validation report

## iOS release checks — 2026-09-05

Checked commit `53f4f2b` with Flutter 3.47.2, Dart 3.13.2 and MSAL iOS
2.15.0. The following checks passed locally:

- Formatting and analysis with fatal infos and warnings.
- All 21 Dart plugin tests and 8 example widget tests.
- Pigeon regeneration with no generated-channel changes.
- Swift plugin compilation for the iOS Simulator.
- Full Runner and XCTest bundle compilation with an iOS 17 deployment target.
- All 4 native XCTest cases on an iPhone 16 Pro simulator running iOS 18.6;
  no failures or skipped tests. These check SDK linkage and typed failures
  before initialization or without a password continuation.
- The Flutter integration test passed on the same simulator from the clean
  snapshot in a directory named `microsoft_entra_external_id`. It invokes
  `getNativeSdkStatus` through the real Flutter/Swift platform channel.
- `dart pub publish --dry-run` from a clean `git archive HEAD` snapshot:
  zero warnings for `0.2.0-dev.3`.

Xcode now discovers standard simulator test destinations, and the full
Runner test build succeeds. This supersedes the simulator discovery and
asset-compiler limitations recorded below on September 1. The initial Flutter
build stalled while Git read files in its separate MSAL checkout; direct
Xcode builds used the workspace's already-resolved SwiftPM dependencies.
Direct Xcode commands need `IPHONEOS_DEPLOYMENT_TARGET=17.0` because the
ephemeral Flutter-generated package initially declares iOS 15.

Running the Flutter integration test from the original checkout also exposed
a SwiftPM package-identity conflict: Flutter's plugin-author integration adds
`microsoft_entra_external_id`, while its generated dependency uses the checkout
basename `oss-flutter-plugin-sdk-entra-id`. Xcode rejects these as duplicate
targets with different package identities. Use a clean checkout whose directory
is named `microsoft_entra_external_id` when validating the example through
Flutter. This is separate from the successful direct Xcode tests above.

The configured example subsequently built and launched on the simulator, but
initialization displayed `MSALErrorDomain -50000`. The simulator app's signature
contained empty entitlements despite the example's declared Keychain group.
Ad-hoc signing with that group caused Simulator to reject launch
(`FBSOpenApplicationServiceErrorDomain 1`, underlying spawn error 153).

The same error was reproduced on a developer-signed iPhone. It was caused by
the missing `msauthv2` and `msauthv3` entries in `LSApplicationQueriesSchemes`.
MSAL validates these schemes when a broker-capable `msauth.<bundle-id>://auth`
redirect URI is configured and reports the validation failure as error `-50000`.
The example now declares both schemes. Its signed Profile artifact was rebuilt,
installed, and launched on the iPhone after the fix. Native-auth SDK
initialization then completed successfully on the physical device.

Reproduce the native checks from `example/ios`:

```sh
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -disableAutomaticPackageResolution build-for-testing \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -disableAutomaticPackageResolution -parallel-testing-enabled NO \
  test-without-building CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0
```

On 2026-09-05, the example was also built as a Profile application with a
locally configured external tenant, signed by an Apple Development profile,
installed on a physical iPhone 15 Pro, and launched successfully from the
Home Screen without Flutter tooling. This confirms that the iOS device can run
the plugin's signed Profile artifact. Authentication credentials were not
entered during this launch.

Stable release remains blocked on live iOS tenant validation: Email OTP and
password sign-in/sign-up, required attributes, password reset, token cache
across process restart, silent and forced refresh with a protected API scope,
sign-out persistence, and explicit browser fallback including its redirect.
No live authentication result is implied by the deterministic tests above.

## Earlier validation — 2026-09-01

Reviewed on 2026-09-01. This report covers the repository bootstrap,
deterministic native password/Email OTP sign-in and sign-up, required
attributes, password reset, token-management slices, and the existing live
Android Email OTP tenant test. It does not establish production readiness or
live-tenant validation of the new password, attribute, and reset flows.

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
- Password and Email OTP sign-in and sign-up.
- Direct password submission and server-driven password continuations for
  sign-in, sign-up, and password reset.
- Required/custom sign-up attributes with native metadata and invalid-value
  feedback.
- Self-service password reset with Email OTP, new password, and automatic
  native sign-in.
- Verification-code submission and resend.
- Automatic sign-in after sign-up.
- ID token and API-scoped access-token results with scopes and expiry.
- Silent MSAL cache retrieval, automatic expired-token refresh, and forced
  access-token refresh without exposing refresh tokens to Dart.
- Sign-out and typed browser-required/error states.
- Explicit system-browser fallback through the native MSAL interactive token
  APIs on Android and iOS.
- Custom Flutter example UI with no embedded WebView.
- SwiftPM-only iOS integration and MSAL keychain entitlement in the example.

## Deterministic gates

The implementation snapshot passed:

```text
Pigeon regeneration + generated-output drift check   PASS
dart format                                           PASS
flutter analyze                                      PASS
flutter test                                        PASS (21 tests)
flutter test (example)                              PASS (8 widget tests)
Android plugin testDebugUnitTest                    PASS (8 native tests)
Android device integration_test native bridge       PASS (1 test)
Android API 35 install/start/native initialization   PASS
Swift Package manifest resolution                    PASS
iOS Swift plugin compilation                         PASS
iOS Simulator install/start/native SDK invocation    PASS
dart pub publish --dry-run (clean Git snapshot)      PASS
repository secret/placeholder scan                   PASS
GitHub CI (main and v0.1.0-dev.1 tag)                PASS
GitHub CI (main and v0.2.0-dev.1 tag)                PASS
pub.dev 0.1.0-dev.1 publication and indexing         PASS
pub.dev 0.2.0-dev.1 publication and indexing         PASS
```

The published package,
[`microsoft_entra_external_id 0.1.0-dev.1`](https://pub.dev/packages/microsoft_entra_external_id),
and its matching
[`v0.1.0-dev.1` GitHub prerelease](https://github.com/Wreos/microsoft_entra_external_id/releases/tag/v0.1.0-dev.1)
come from the same validated commit.

The feature snapshot is published as
[`microsoft_entra_external_id 0.2.0-dev.1`](https://pub.dev/packages/microsoft_entra_external_id/versions/0.2.0-dev.1),
with the matching
[`v0.2.0-dev.1` GitHub prerelease](https://github.com/Wreos/microsoft_entra_external_id/releases/tag/v0.2.0-dev.1).
Both are development previews; the new password sign-up, required-attribute,
and password-reset paths still need live-tenant checks before a stable release.

The iOS build resolves `MSAL` `2.15.0` from the official Microsoft repository
and compiles the password delegates and token-cache adapter for both simulator
architectures. The local full Runner build currently stops later in Apple's
asset compiler because the installed iOS 26.5 CoreSimulator cannot create its
requested device. CocoaPods is not part of the package or validation graph.

The Android aggregate `testDebugUnitTest` task also executes tests shipped
inside Flutter's `integration_test` module. Three of those upstream Mockito
tests fail on this Java/AGP environment before the plugin task completes. The
scoped plugin native test task passes, and the complete example APK builds.
This upstream test-runner incompatibility is not hidden as a plugin pass.

The example was also installed and started on a Pixel Tablet Android 15
emulator. With syntactically valid non-production identifiers, the official
MSAL native client initialized, cached-account lookup returned signed-out, and
the custom Flutter sign-in/sign-up screen rendered without an embedded WebView.
This verifies device-level bridge wiring without relying on tenant
configuration.

The scenario-catalog example was installed on a physical Motorola device with
the live tenant configuration. Its Email OTP, Password, Attributes, Password
Reset, and More destinations all rendered and switched independently through
Material navigation. Widget tests exercise every destination without displaying
raw access-token or ID-token values.

## Environment and live-test boundaries

The iOS app was ad-hoc signed with the example's MSAL keychain entitlement,
installed, and started on an isolated iPhone 17 Pro simulator. With
syntactically valid non-production identifiers, the official MSAL native client
initialized, cached-account lookup returned signed-out, and the Flutter
sign-in/sign-up screen rendered. This verifies the iOS runtime bridge and native
SDK invocation, not a live-tenant authentication result. Xcode does
not discover devices from this isolated device set as test destinations, so
XCTest execution remains a manual release gate even though the XCTest bundle
compiles for both simulator architectures.

The complete Email OTP sign-up, automatic sign-in, sign-out, and subsequent
sign-in flow passed against a real Microsoft Entra External ID tenant on a
physical Android device. Tenant identifiers and the test account are not stored
in the repository. The equivalent iOS live-tenant flow remains required before
claiming cross-platform parity.

Password sign-in also passed on the physical Android device. The live flow
returned an ID token and an access token, completed an explicit forced access
token acquisition, signed out, and remained signed out after the app process
was restarted. The run used the SDK's default OpenID scopes; a custom API scope
was not configured and remains an Android/iOS live-test gate. Password sign-in
and token retrieval still require the equivalent iOS live-tenant test.

The deterministic gates cover password sign-up, required attributes, password
reset, explicit unsupported MFA/strong-auth mapping, and browser-required
result mapping. The new password/attribute/reset flows still need live-tenant
checks on a physical Android device and iOS before a stable release. The
browser fallback bridge is
compile-tested on both platforms but still needs a live tenant with a
registered redirect URI and callback configuration. A browser-required MSAL
result is exposed to Dart; the host must explicitly call
`signInWithBrowser(...)` instead of relying on an automatic switch after an SDK
error or fallback signal.
