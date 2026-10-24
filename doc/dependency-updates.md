# Dependency update review

## Review on 2026-10-24

| Dependency | Previous | Updated | Compatibility review |
| --- | --- | --- | --- |
| MSAL Android | 8.5.0 | 8.6.0 | Updates common to 25.0.0 and fixes MsalArgumentException field mapping. Adds upstream Native Auth V2 sign-up; this plugin continues using its existing native-auth APIs. Keep the exact pin and SDK status/test expectation aligned. |
| Pigeon | 29.0.8 | 29.0.11 | Changes focus on optional FFI/JNI generation. Regenerating the method-channel Dart, Kotlin, and Swift files changes only the generator version header. |
| Gradle | 9.8.1 | 9.8.2 | Patch update within 9.8; keep Java 17 and the existing AGP DSL compatibility settings. |
| actions/setup-java | 6.0.1 | 6.1.0 | Keep the Java 17 configuration and pin the action by commit SHA. |
| gradle/actions/setup-gradle | 6.3.0 | 6.4.0 | Keep the configured Gradle version and pin the action by commit SHA. |

MSAL iOS 2.16.0, AGP 9.4.1, Kotlin 2.4.21, Mockito 5.24.0, JUnit
6.1.3, meta 1.19.0, flutter_lints 6.0.0, and cupertino_icons 2.0.0 remain
current stable releases at review time. Flutter SDK-pinned transitive packages
remain under SDK control. The example lockfile refreshes compatible dependencies.

Sources: [MSAL Android 8.6.0](https://github.com/AzureAD/microsoft-authentication-library-for-android/releases/tag/v8.6.0),
[Pigeon changelog](https://pub.dev/packages/pigeon/changelog),
[Gradle 9.8.2](https://docs.gradle.org/9.8.2/release-notes.html),
[setup-java 6.1.0](https://github.com/actions/setup-java/releases/tag/v6.1.0),
[Gradle actions 6.4.0](https://github.com/gradle/actions/releases/tag/v6.4.0).

Validation on Flutter 3.47.7 / Dart 3.13.5:

- Formatting and fatal analyzer checks passed.
- Package tests: 21 passed; example widget tests: 8 passed.
- Android plugin native tests on Java 17: 8 passed; example debug APK built.
- Pigeon regeneration is reproducible across all three languages.
- Publish dry-run from a clean Git snapshot: 0 warnings.
- Native SDK status integration test on the temporary Android API 36 emulator: passed.
- Example app launched on a temporary Android API 36 emulator; hot reload
  succeeded and the Dart/Flutter tooling reported no runtime errors.
- iOS plugin target compiled for arm64 and x86_64 simulators.
- iOS Runner simulator build passed with `CODE_SIGNING_ALLOWED=NO` and
  `COMPILATION_CACHE_CAS_PATH=/tmp/entra-update-xcode-cache`. The default local
  cache location on the external disk fails; no SDK or repository workaround
  was committed.

Live tenant authentication is a separate check.

## Previous review on 2026-10-10

Reviewed on 2026-10-10 against stable upstream releases. Native MSAL and Pigeon
versions remain exact pins. The package still requires Flutter 3.47+, Dart
3.13.2+, Android API 24+, Java 17, and iOS 17+.

| Dependency | Previous pin/constraint | Updated pin/constraint | Compatibility review |
| --- | --- | --- | --- |
| MSAL Android | 8.4.2 | 8.5.0 | Adds private-preview V2 interfaces and updates common to 24.7.0. Kotlin moves to 2.0.21 with language/API level 1.9. No required migration is documented for the existing native-auth APIs. |
| MSAL iOS | 2.15.0 | 2.16.0 | Adds Native Auth V2 flows. The SwiftPM manifest requires iOS 17, matching this plugin. Existing native-auth APIs remain in use; this update does not expose V2 or MFA. |
| Pigeon | 28.0.0 | 29.0.8 | Adds experimental FFI/JNI and requires at least Flutter 3.41/Dart 3.11. We retain method channels and regenerate Dart, Kotlin, and Swift together. Generated host signatures are unchanged. |
| plugin_platform_interface | ^2.0.2 | ^2.1.8 | Already resolved to 2.1.8; raise the declared floor to the tested version. Its newer SDK minimums are below this package's requirements. |
| Cupertino Icons (example) | ^1.0.8 (locked 1.0.9) | ^2.0.0 | Major release requires Flutter 3.44/Dart 3.12 and migrates upstream Cupertino usage to cupertino_ui. The example uses Material UI and does not import Cupertino widgets or icons. |
| Android Gradle plugin | plugin 9.1.0 / example 9.4.0 | 9.4.1 | AGP 9.4 requires Gradle 9.6+, Java 17, and Build Tools 36.0.0. Keep the existing Flutter-compatible android.newDsl=false setting; its removal in AGP 10 will require a separate migration. |
| Kotlin Gradle plugin | plugin 2.4.0 / example 2.4.10 | 2.4.21 | Patch release; keep the plugin and example declarations aligned. Android continues using AGP's built-in Kotlin. |
| Gradle wrapper | 9.7.1 | 9.8.1 | Includes security fixes. The 9.x upgrade guide notes embedded Kotlin and internal API changes; this build uses AGP 9 and does not intentionally access those internals. |
| Mockito | 5.0.0 | 5.24.0 | Remains within major 5. Inline mocking was already the default in 5.0.0. No Mockito API migration is needed by the current native tests. |

`meta`, `flutter_lints`, and JUnit are already at their latest stable releases.
Root and example dependency resolution also upgrades compatible transitive
packages. Flutter SDK-pinned `material_color_utilities` and `test_api` stay at
the versions selected by the pinned Flutter SDK; do not override them independently.
The library's root pubspec.lock remains untracked; the example lock is committed.

## Flutter SDK maintenance

Development and CI now use Flutter 3.47.7 / Dart 3.13.5, the stable hotfix
available on 2026-10-10. The 3.47.3-3.47.7 changelog includes Xcode 27 debug
startup, iOS device debugging, SwiftPM diagnostics, and iOS accessibility fixes.
The native-assets iOS floor rises to 15, below this plugin's iOS 17 floor.
No package API migration is required by these hotfixes.

Flutter 3.47.7's Gradle plugin still casts to `AbstractAppExtension` and uses
`libraryVariants`; keep `android.newDsl=false` until stable Flutter supports
the new AGP DSL. Removing that compatibility setting now would break the host.
Do not patch the installed Flutter SDK to hide that upstream dependency.

## Upstream sources

- [Flutter stable hotfix changelog](https://github.com/flutter/flutter/blob/3.47.7/CHANGELOG.md)
- [MSAL Android 8.5.0 release](https://github.com/AzureAD/microsoft-authentication-library-for-android/releases/tag/v8.5.0)
- [MSAL iOS 2.16.0 release](https://github.com/AzureAD/microsoft-authentication-library-for-objc/releases/tag/2.16.0)
- [MSAL iOS 2.16.0 package manifest](https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/2.16.0/Package.swift)
- [Pigeon changelog](https://pub.dev/packages/pigeon/changelog)
- [Platform interface changelog](https://pub.dev/packages/plugin_platform_interface/changelog)
- [Cupertino Icons changelog](https://pub.dev/packages/cupertino_icons/changelog)
- [AGP 9.4 compatibility and release notes](https://developer.android.com/build/releases/agp-9-4-0-release-notes)
- [Kotlin 2.4.21 release](https://github.com/JetBrains/kotlin/releases/tag/v2.4.21)
- [Gradle 9.8.1 release notes](https://docs.gradle.org/9.8.1/release-notes.html)
- [Gradle 9.x upgrade guide](https://docs.gradle.org/9.8.1/userguide/upgrading_version_9.html)
- [Mockito releases](https://github.com/mockito/mockito/releases)

## Automated updates

Weekly Dependabot jobs cover pub at the root and example, Gradle in both
`/android` and `/example/android`, SwiftPM in `/ios/microsoft_entra_external_id`,
and GitHub Actions. Android toolchain updates are grouped across both Gradle
locations; MSAL and native test dependencies get separate update PRs.
SwiftPM coverage already existed; the missing Android plugin location is now
included. The configuration takes effect when merged into the default branch.
See [GitHub's directories and grouping reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference).

For each native SDK PR, update the native SDK status version and its native test
expectation as well as the manifest pin. Resolve the iOS host with Xcode to
refresh `example/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
For Pigeon PRs, regenerate all three languages before running CI.
Run the checks in [CONTRIBUTING.md](../CONTRIBUTING.md) and native validation.
Live tenant authentication remains a separate release check.

## Validation of this update

- Dart and Flutter plugin analyzer and fatal CLI analysis: no issues.
- Formatting: unchanged after formatting all package and example Dart sources.
- Package tests: 21 passed; example widget tests: 8 passed.
- Android plugin native tests on Java 17: 8 passed; example debug APK built.
- Pigeon regeneration: identical Dart, Kotlin, and Swift outputs on a second run.
- Android plugin native tests with Java 17: 8 passed.
- All Dart checks and Android native tests also passed after upgrading Flutter
  to 3.47.7 / Dart 3.13.5.
- iOS plugin target: compiled for arm64 and x86_64 simulators against MSAL 2.16.0.
  The build used `COMPILATION_CACHE_CAS_PATH=/tmp/entra-dependency-xcode-cache`
  to bypass an invalid local Xcode cache path.
- Android API 36 emulator: native SDK status crossed the Flutter platform bridge.
  Used a fresh source copy outside the cloud-managed workspace and a temporary
  emulator because old build artifacts were offloaded and the existing emulator
  lacked install space.
- Example app hot reload through the Dart and Flutter plugin: succeeded, with no
  reported runtime errors.
- Dependabot YAML parsed successfully; configured manifest directories exist.

- iOS 26.5 simulator on an iPhone 16 Pro: Runner built and launched locally;
  all 5 XCTest cases passed, including native-client initialization without
  contacting a tenant. The browser callback no longer captures non-Sendable
  plugin state.
- Flutter iOS integration tests: both passed (native SDK status over the bridge
  and initialization with public tenant configuration and the iOS redirect URI).
- Normal Flutter iOS app launch and hot reload through the Dart and Flutter
  plugin: succeeded; no reported runtime errors, and the UI showed successful
  native initialization.

### Local simulator environment

CoreSimulator could not write its device set through the local
`~/Library/Developer` symlink to an external disk. The original symlink is
preserved at `~/Library/Developer.external-backup-20261010`. CoreSimulator now
uses an internal-disk directory; other Developer directories still link to
their original external locations. Existing external data was preserved.

The Runner simulator build uses local ad-hoc signing (`CODE_SIGNING_ALLOWED=YES`,
`CODE_SIGN_IDENTITY=-`) and the cache-path override above. An unsigned build
alone does not verify that MSAL can initialize; run the native initialization
test and the configured Flutter integration smoke test as well.

The local example configuration had a redirect URI that did not match the iOS
host. Simulator validation used
`msauth.io.github.wreos.microsoftEntraExternalIdExample://auth` in temporary
public configuration; the original `.env.local` was preserved. Actual browser
authentication also requires registering this redirect URI in Entra.

Old SwiftPM artifacts in this cloud-managed checkout also mixed the repository
folder identity `oss-flutter-plugin-sdk-entra-id` with the package identity
`microsoft_entra_external_id`. For Flutter device validation, use a clean local
checkout named `microsoft_entra_external_id` and resolve its packages afresh.
Do not hand-edit generated SwiftPM manifests or change the public package name
to accommodate stale local artifacts.

Live tenant sign-in, sign-up, password reset, refresh, sign-out, and browser
fallback need their usual release checks.
