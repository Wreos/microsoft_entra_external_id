# Microsoft Entra External ID native-authentication example

This app mirrors Microsoft's native-authentication samples while keeping the UI
in Flutter:

- restore a cached account;
- sign in with email/username and password or Email OTP;
- sign up with Email OTP;
- submit or resend the verification code;
- acquire an API-scoped access token and force an MSAL cache refresh;
- automatically sign in after sign-up;
- sign out.

There is no embedded WebView. Android calls MSAL Native Auth directly and iOS
calls `MSALNativeAuthPublicClientApplication` through Swift Package Manager.

## External tenant setup

Before running the app, complete Microsoft's prerequisites for an **external
tenant**:

1. Register an application and record its Application (client) ID.
2. Under **Authentication > Advanced settings**, enable both mobile/desktop
   public client flows and native authentication.
3. Create an Email one-time passcode or Email with password sign-up/sign-in user
   flow and associate the application with it.
4. Grant the API permissions required by your scenario.

Use only the tenant prefix. For `contoso.onmicrosoft.com`, pass `contoso`.

## Run

```shell
flutter run \
  --dart-define=ENTRA_CLIENT_ID=<application-client-id> \
  --dart-define=ENTRA_TENANT_SUBDOMAIN=<tenant-prefix> \
  --dart-define=ENTRA_API_SCOPE=api://<api-client-id>/<delegated-scope>
```

`ENTRA_API_SCOPE` is optional. Without it, MSAL requests its default OIDC
scopes. Enter a password to use password sign-in, or leave the password field
empty to let the tenant select Email OTP or return a password continuation.

The client ID, tenant prefix, and scope are public client configuration, not
secrets. Do not add a client secret to this example or any mobile application.
Never print or persist the entered password, access token, or ID token.

The iOS Runner already contains the MSAL keychain access-group entitlement.
Select your own development team when signing for a physical Apple device.

Microsoft references:

- [Prepare Android for native authentication](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app)
- [Run the iOS native-authentication sign-in sample](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in)
