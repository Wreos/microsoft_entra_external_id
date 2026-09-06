# Validation

## Release 0.2.0, 2026-09-06

Toolchain: Flutter 3.47.2, Dart 3.13.2, Pigeon 28.0.0, MSAL Android 8.4.2, and
MSAL iOS 2.15.0.

Passed locally:

- `dart format --output=none --set-exit-if-changed` for the package and example.
- `flutter analyze --fatal-infos --fatal-warnings`.
- 21 package tests and 8 example widget tests.
- Pigeon regeneration with no generated-file drift.
- Android plugin unit tests (8 tests).
- iOS Swift plugin, Runner, and XCTest bundle compilation for iOS 17.
- Four iOS XCTest cases on an iPhone 16 Pro simulator running iOS 18.6.
- Flutter integration and configured native-client smoke tests on the same
  simulator.
- `dart pub publish --dry-run` from a clean `git archive HEAD` snapshot with
  zero warnings.

Live iOS checks against a local External ID tenant passed for Email OTP sign-in
and sign-up, password sign-up and sign-in, required attributes, password reset,
cached-account persistence, sign-out persistence, protected-scope token refresh,
and the registered system-browser redirect. The browser check reached the iOS
app-to-identity-provider authorization prompt. Credentials, codes, tenant test
accounts, and token values were supplied only at runtime and were not stored in
the repository.

The example also built, installed, and launched as a signed Profile app on a
physical iPhone 15 Pro from the Home Screen.

## Limits

The package does not yet implement MFA, strong-auth registration, or
process-recreation recovery. Browser callback completion and advanced tenant
policies still need broader live coverage. Passing compilation or deterministic
tests does not replace a host application's own tenant and device validation.

## Reproduce the iOS build

Run from `example/ios`:

```sh
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -disableAutomaticPackageResolution build-for-testing \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0
```

For a configured simulator smoke test, use a clean checkout named
`microsoft_entra_external_id`. Store local values in ignored
`example/.env.local` and pass them through `--dart-define`; do not print or
commit them.
