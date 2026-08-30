# Toolchain and dependency baseline

Verified on 2026-08-30. Versions are exact where build reproducibility matters.
Revalidate the Microsoft SDK pins on the day each native integration stage
starts.

## Flutter and Dart

- Development and CI Flutter: `3.47.2` stable.
- Dart: `3.13.2`.
- Package minimum: Flutter `3.47.0`, Dart `3.13.2`.
- Pigeon generator: `28.0.0`.

The repository follows Flutter's current plugin template and its
[built-in Kotlin migration for plugin authors][flutter-built-in-kotlin].
The minimum is deliberate: supporting older Flutter versions would require a
second Android build setup before the public API exists.

## Android

- Android Gradle Plugin: `9.1.0`.
- Gradle: `9.3.1`.
- Kotlin version declaration: `2.4.0`; compilation uses AGP 9 built-in Kotlin
  and does not apply the deprecated `kotlin-android` plugin.
- Java language level and build JDK: `17`.
- `compileSdk`: `36`.
- `minSdk`: `24`.
- Android unit tests: JUnit `6.1.3` on JUnit Platform.
- Next native integration candidate: MSAL Android `8.4.1`.

`android.newDsl=false` is retained because Flutter 3.47 still casts AGP 9's
extension to `AbstractAppExtension`; removing the switch fails the example
build. KGP 2.4 remains version-declared so Flutter's dependency validator sees
a supported Kotlin baseline, while AGP built-in Kotlin performs compilation and
the deprecated `kotlin-android` plugin is not applied. Re-test and remove both
compatibility declarations once Flutter and AGP expose one converged baseline.

## iOS

- Xcode used by the bootstrap validation: `26.6`.
- Swift Package Manager and CocoaPods plugin manifests are retained.
- Minimum deployment target: iOS `17.0`.
- Next native integration candidate: MSAL iOS `2.15.0`.

iOS 17 is selected because the official MSAL iOS `2.15.0` package and podspec
both require it. Lowering the plugin target would mean pinning an older MSAL
release and creating dependency debt before the first native flow exists.

## Dependency policy

- Pin build generators and native SDKs exactly; do not use floating versions
  such as `8.+`.
- The bootstrap does not link MSAL yet. Its diagnostic reports `linked: false`
  until a native client is actually integrated and covered by native tests.
- Add automated dependency-update pull requests with CI before the first
  prerelease.
- A native version bump must pass Dart contracts, native unit tests, both
  example builds, and live External ID smoke tests.

[flutter-built-in-kotlin]: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
[flutter-plugin-guide]: https://docs.flutter.dev/packages-and-plugins/developing-packages
[flutter-347]: https://docs.flutter.dev/release/release-notes/release-notes-3.47.0
[msal-android-841]: https://github.com/AzureAD/microsoft-authentication-library-for-android/releases/tag/v8.4.1
[msal-ios-2150]: https://github.com/AzureAD/microsoft-authentication-library-for-objc/releases/tag/2.15.0
[pigeon]: https://pub.dev/packages/pigeon
