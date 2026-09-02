# Contributing to Microsoft Entra External ID for Flutter

This project is an unofficial Flutter bridge to the official Microsoft Entra
External ID Native Authentication SDKs. Flutter owns the UI. MSAL owns the
authentication protocol and native token cache.

Preserve that boundary in every contribution. Do not introduce a Dart OAuth
implementation, an embedded WebView, browser-first MSAL, or refresh tokens in
the Dart or Pigeon contracts.

## Before you start

- Search existing issues and pull requests to avoid duplicate work.
- Open an issue before starting a large feature or behaviour change so we can
  discuss the approach first.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- Report vulnerabilities privately as described in the
  [security policy](SECURITY.md), not in a public issue.

## Development setup

You need Flutter 3.47 or later, Dart 3.13.2 or later, Java 17 for Android,
and Xcode with an iOS 17 or later runtime for iOS work.

```sh
git clone https://github.com/Wreos/microsoft_entra_external_id.git
cd microsoft_entra_external_id
flutter pub get
(cd example && flutter pub get)
```

The example uses public tenant configuration supplied at runtime. Never commit
tenant test accounts, passwords, OTPs, client secrets, tokens, continuation
data, or personally identifiable information.

## Making a change

Keep changes focused. If you change behaviour, update the contract tests. For a
Pigeon contract change, edit `pigeons/native_auth_api.dart` and regenerate every
platform channel together:

```sh
dart run pigeon --input pigeons/native_auth_api.dart
dart format lib/src/generated/native_auth_api.g.dart
```

Do not hand-edit generated Dart, Kotlin, or Swift channel files. Pin native
MSAL versions exactly, preserve Swift Package Manager as the iOS dependency
path, and keep Android API 24+, Java 17, and iOS 17+ compatibility.

## Validate before opening a pull request

Run the package checks from the repository root:

```sh
dart format --output=none --set-exit-if-changed \
  lib test pigeons example/lib example/test example/integration_test
flutter analyze --fatal-infos --fatal-warnings
flutter test
(cd example && flutter test)
```

For Android or iOS changes, run the relevant native and device tests when your
environment allows it. For release-related changes, run `dart pub publish
--dry-run` from a clean Git snapshot. CI validates the Dart plugin contract,
Android plugin module, and iOS plugin target. It does not run the example app
or live-tenant scenarios.

## Pull requests

Use the pull-request template to explain the problem, the chosen solution, and
how you tested it. Update documentation and the changelog when users are
affected. Keep generated code in sync, and leave unrelated formatting or
refactors out of the change.

By contributing, you agree that your contributions are licensed under this
repository's [MIT License](LICENSE).
