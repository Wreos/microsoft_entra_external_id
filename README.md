# Entra External ID for Flutter

An experimental, unofficial Flutter bridge for Microsoft Entra External ID
Native Authentication through the official MSAL Android and iOS SDKs.

The goal is to let a Flutter application own its sign-up and sign-in UI while
MSAL handles the authentication protocol, native token cache, and platform
behavior.

> [!WARNING]
> This repository is in bootstrap. MSAL is not linked yet and no authentication
> flow is usable. Do not add this package to a production application.

## Current milestone

The bootstrap milestone establishes:

- a Flutter plugin for Android and iOS, implemented in Kotlin and Swift;
- a typed Pigeon channel shared by Dart and the native platforms;
- a diagnostic `getNativeSdkStatus()` call that reports `linked: false` until
  the native MSAL dependencies are integrated;
- Dart, Android, iOS, example, and integration-test locations;
- a gate-based implementation and validation plan.

Read [INTENT.md](INTENT.md) for product scope and
[doc/IMPLEMENTATION_PLAN.md](doc/IMPLEMENTATION_PLAN.md) for the execution
sequence. The verified toolchain and deployment floors are recorded in
[doc/STACK.md](doc/STACK.md), and the exact bootstrap evidence and environment
limitations are recorded in [doc/VALIDATION.md](doc/VALIDATION.md).

## Requirements

- Flutter 3.47 or newer and Dart 3.13.2 or newer;
- Android API 24 or newer, with a Java 17 build JDK;
- iOS 17 or newer and a current Xcode toolchain.

## Scope

This plugin targets **external tenants** in Microsoft Entra External ID. It is
not intended for workforce Entra ID, legacy Azure AD B2C compatibility, or
browser-only MSAL flows.

The host Flutter app will own the UI. The plugin will expose native
authentication as typed states and continuations. Browser fallback will remain
explicit for flows that cannot stay native.

On Android, the implementation target is Microsoft's
`INativeAuthPublicClientApplication`, created with
`createNativeAuthPublicClientApplication(...)` as documented in the official
[Native Authentication tutorial][native-auth-android]. Browser-based MSAL and
embedded WebViews are not the core authentication path.

On iOS, the corresponding implementation target is
`MSALNativeAuthPublicClientApplication` plus its typed delegate states, following
Microsoft's [iOS Native Authentication quickstart][native-auth-ios].

## Bootstrap check

```dart
final status = await EntraExternalId().getNativeSdkStatus();

// false during bootstrap; becomes true only after the platform MSAL SDK is
// actually linked and registered.
print(status.linked);
```

## Contributing

The public API is not stable. Before implementing a new flow, update its
contract tests and pass the validation gate defined in the implementation plan.

[native-auth-android]: https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app
[native-auth-ios]: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in
