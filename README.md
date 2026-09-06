# Microsoft Entra External ID for Flutter

An unofficial, independent Flutter bridge for Microsoft Entra External ID
native authentication. Flutter owns the UI. MSAL owns the protocol and native
token cache. This project is not affiliated with, endorsed by, or sponsored by
Microsoft.

<p align="center">
  <img src="https://raw.githubusercontent.com/Wreos/microsoft_entra_external_id/main/doc/assets/example-email-otp.png" width="240" alt="Email OTP sign-in example">
</p>

## Supported flows

- Email OTP and password sign-in and sign-up.
- Required sign-up attributes and password reset.
- Cached-account lookup, access and ID tokens, silent and forced refresh, and
  sign-out.
- Explicit system-browser fallback.

MFA, strong-auth registration, and process-recreation recovery are not
implemented.

## Requirements

- Flutter 3.47+ and Dart 3.13.2+.
- Android API 24+ with Java 17.
- iOS 17+.

The package supports Microsoft Entra External ID external tenants. It does not
support workforce Entra ID, Azure AD B2C compatibility, embedded WebViews, or a
Dart OAuth implementation.

## Start here

1. Follow the [tutorial](doc/tutorial.md) to configure a tenant and initialize
   the client.
2. Use the [how-to guides](doc/how-to.md) for OTP, attributes, reset, tokens,
   and browser fallback.
3. Consult the [reference](doc/reference.md) for methods, states, and platform
   requirements.
4. Read the [architecture and security notes](doc/explanation.md) before
   handling credentials or tokens.

The [example](example/README.md) is a runnable Flutter app with separate Email
OTP, Password, Attributes, Password Reset, and browser-fallback screens.

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Report
vulnerabilities under [SECURITY.md](SECURITY.md). API changes before `1.0.0`
follow the [migration policy](doc/MIGRATION.md).
