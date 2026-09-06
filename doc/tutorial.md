# Tutorial: add native authentication

Use this tutorial to add Email OTP or password sign-in to a Flutter app backed by
Microsoft Entra External ID.

## 1. Add the package

```sh
flutter pub add microsoft_entra_external_id
```

Your app needs Flutter 3.47+, Dart 3.13.2+, Android API 24 with Java 17, and
iOS 17+.

## 2. Configure the external tenant

Create a Microsoft Entra External ID application and enable Native
Authentication. Configure an Email OTP or Email with password user flow. Record
the application client ID and the tenant prefix. For
`contoso.onmicrosoft.com`, the prefix is `contoso`.

If your app can use browser fallback, register its platform redirect URI. On
iOS, use `msauth.<bundle-id>://auth` and enable the MSAL keychain group. On
Android, register the matching MSAL callback activity and redirect URI. The
[example](../example/README.md) shows both platform configurations.

## 3. Initialize the client

```dart
final entra = MicrosoftEntraExternalId();

await entra.initialize(
  const NativeAuthConfiguration(
    clientId: 'application-client-id',
    tenantSubdomain: 'contoso',
    redirectUri: 'msauth.com.example.app://auth',
  ),
);
```

Client ID, tenant prefix, redirect URI, and API scopes are public mobile
configuration. Do not add a client secret to a Flutter app.

## 4. Start sign-in

Collect the email and password in your Flutter UI, then call:

```dart
final state = await entra.signInWithPassword(
  email,
  password,
  scopes: const ['api://your-api-client-id/access_as_user'],
);
```

Clear the password controller after the call. Handle `NativeAuthSignedIn` by
using its token only with the intended HTTPS API. Keep tokens in memory and do
not log them.

If the tenant asks for a password after a username-first sign-in, the result is
`NativeAuthPasswordRequired`. Submit the same state with
`submitPassword(state, password)`. For Email OTP, handle
`NativeAuthCodeRequired` with `submitCode(state, code)`.

Continue with the [how-to guides](how-to.md) for sign-up, password reset,
attributes, token refresh, and browser fallback.
