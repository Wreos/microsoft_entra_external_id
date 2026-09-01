# Password sign-up, attributes, and password reset

## Goal

Add the remaining account-creation and recovery flows needed by a customized
Flutter authentication UI:

- sign up with an email and password;
- collect tenant-defined required and custom string attributes;
- reset a password with email OTP verification;
- automatically sign in after successful sign-up or password reset.

The plugin remains a bridge to the pinned Microsoft MSAL Native
Authentication SDKs. Flutter owns the screens and input collection. Android
and iOS MSAL own the protocol, continuation state, and token cache.

## Shared contract

`signUp` accepts an optional password and a map of string attributes. A
`signUpWithPassword` convenience method makes the primary password flow
explicit. Attribute names are passed through unchanged so built-in and custom
tenant attributes are both supported.

When MSAL needs more data, the plugin returns typed states:

- `NativeAuthAttributesRequired` contains the opaque continuation handle plus
  each required attribute's name, native type, required flag, and validation
  regex;
- `NativeAuthCodeRequired` is reused for sign-up and password reset OTPs;
- `NativeAuthPasswordRequired` is reused for sign-up and password reset
  password submission.

`NativeAuthOperation.passwordReset` distinguishes recovery continuations from
sign-in and sign-up. `submitAttributes`, `submitCode`, `submitPassword`, and
`resendCode` dispatch only to the matching in-memory native state.

## Native mapping

Android MSAL 8.4.2 uses `UserAttributes` with string values and exposes
`RequiredUserAttribute` metadata. iOS MSAL 2.15.0 accepts `[String: Any]`, but
the cross-platform public contract intentionally uses strings because that is
the portable capability of the pinned Android SDK.

After sign-up or password reset completes, the plugin uses the continuation
provided by MSAL to sign in and returns the existing `NativeAuthSignedIn`
result. Refresh tokens remain inside the native MSAL cache.

## Safety and failure behavior

Passwords, OTPs, attribute values, and native continuation objects stay in
memory and are never logged. Dart receives only opaque continuation IDs.
Browser-required errors remain an explicit signal to the host application;
the plugin never silently changes authentication mechanisms.

## Validation

Add contract tests before native implementation, native Android unit tests,
iOS target compilation/tests, Flutter example coverage for each UI state, and
live-tenant device checks for password sign-up, required attributes, and
password reset before the next prerelease.
