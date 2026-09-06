# Implementation status and roadmap

## Current implementation

The package uses the official Microsoft Entra External ID Native Authentication
SDKs: `INativeAuthPublicClientApplication` on Android and
`MSALNativeAuthPublicClientApplication` on iOS. Flutter owns the UI; MSAL owns
the protocol and native token cache.

Implemented on Android and iOS:

- Email OTP and password sign-in and sign-up.
- Required and custom sign-up attributes.
- Password reset with Email OTP and a new password.
- Code, password, and attribute continuations plus code resend.
- Automatic sign-in after sign-up or reset.
- Cached-account lookup, ID and access tokens, silent and forced refresh, and
  sign-out.
- Explicit system-browser fallback through native MSAL interactive APIs.

The public contract is generated from `pigeons/native_auth_api.dart`. Native
objects, refresh tokens, and continuation state remain private to each plugin
instance.

## Delivery rules

- Do not replace Native Authentication with a Dart OAuth implementation,
  embedded WebView, or browser-first MSAL.
- Pin native SDK versions exactly. Use Swift Package Manager only on iOS.
- Regenerate every Pigeon target after a contract change.
- Keep passwords, one-time codes, continuation data, and tokens out of logs,
  fixtures, and source control.
- A native SDK error returns a typed failure. Only the host can start browser
  fallback after `browserRequired`.

## Validation

Every change needs formatting, fatal analysis, Dart tests, and the relevant
native tests. Release changes also need a clean-snapshot `dart pub publish
--dry-run` and live device checks for the flow being changed. See
[VALIDATION.md](VALIDATION.md) for the recorded matrix.

## Remaining work

- MFA and strong-auth registration.
- Typed cancellation and correlation metadata without PII.
- Lifecycle coverage for duplicate submissions, stale continuations,
  reinitialization, engine detach, multiple engines, backgrounding, and process
  recreation.
- Broader live tests for browser callback completion and advanced tenant policy.
