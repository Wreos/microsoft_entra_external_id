# Bootstrap validation report

Validated on 2026-08-30. This report covers Stages 0 and 1 only. MSAL is not
linked, no authentication flow is implemented, and no live-tenant result is
claimed.

## Environment

- Flutter `3.47.2` stable, framework revision `d3b14c8769`.
- Dart `3.13.2`; DevTools `2.60.0`.
- Android CLI `1.0.15985488`.
- Android Gradle Plugin `9.1.0`; Gradle `9.3.1`; Java `17.0.18`.
- Xcode `26.6`; CocoaPods `1.16.2`.
- Pigeon `28.0.0`.

## Stage 0 — Intent

- Cross-checked the product boundary against Microsoft's Android and iOS Native
  Authentication guides.
- Recorded External ID as the supported tenant type and custom Flutter UI as
  the product value.
- Made the native client types an architectural invariant:
  `INativeAuthPublicClientApplication` on Android and
  `MSALNativeAuthPublicClientApplication` on iOS.
- Kept browser fallback explicit and excluded an embedded WebView from the core
  implementation.

## Stage 1 — Repository bootstrap

The final bootstrap snapshot passed:

```text
dart run pigeon, then format generated output        PASS
dart format --output=none --set-exit-if-changed ...   PASS
flutter analyze                                      PASS
flutter test                                         PASS (4 tests)
flutter test (example)                               PASS (1 test)
./gradlew testDebugUnitTest                          PASS
flutter build apk --debug (example)                  PASS
pod ipc spec ios/entra_external_id.podspec           PASS
Swift Package Manager manifest resolution            PASS
xcodebuild build (plugin/example)                    PASS
xcodebuild build-for-testing                         PASS
template-placeholder scan                            PASS
flutter pub publish --dry-run (clean Git snapshot)   PASS
```

Pigeon generation and its required formatting step were run again together and
checked for repository drift. The public diagnostic remains intentionally
honest: both native
implementations return `linked: false` and no SDK version until MSAL is added in
the platform integration stages.

### Android decisions validated

The example and plugin compile with AGP 9 built-in Kotlin. The deprecated
`kotlin-android` plugin is version-declared for Flutter's dependency validator
but is not applied to either module.

Removing `android.newDsl=false` was tested and failed inside Flutter 3.47 with
an AGP extension cast to `AbstractAppExtension`. The flag is therefore a
documented Flutter compatibility requirement, not an unexamined legacy option.
It must be re-tested on every Flutter upgrade.

Android native tests run on JUnit `6.1.3`. The initial `kotlin.test.Test`
configuration did not provide a discovered Gradle test; migrating to JUnit
Platform made native test execution explicit and verifiable.

### iOS validation boundary

Swift Package Manager resolves and the plugin, Runner, and XCTest bundle all
compile when the checkout directory has the package name `entra_external_id`.
The current Codex workspace directory has a task-generated name, so validation
used a temporary, unchanged checkout with the normal repository basename.

After `flutter pub get`, Flutter's generated plugin aggregator starts at the
framework default iOS target. The required `flutter build ios --config-only`
phase reads the Runner's iOS 17 deployment target and raises the generated
package before `xcodebuild`; the validation repeats that production sequence.

`build-for-testing` passed, but XCTest execution could not start because this
machine exposes zero usable iOS Simulator devices. Xcode reported simulator
devices stuck in creation, and XcodeBuildMCP independently returned an empty
simulator list. No repository workaround was committed. Running the test bundle
on a healthy simulator remains a required CI and release gate.

## Remaining gate before native implementation

Stage 2 must define the cross-platform public state machine before either MSAL
dependency is linked. Stage 3 and Stage 4 must then revalidate the exact current
MSAL releases, run native mapping tests, and pass live External ID password and
email-OTP smoke tests on their respective platforms.
