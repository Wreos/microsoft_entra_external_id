# Microsoft Entra External ID native-authentication example

This app mirrors the simple Email one-time-passcode flow from Microsoft's
official native-authentication samples, while keeping the UI in Flutter:

- restore a cached account;
- sign in or sign up with an email address;
- submit or resend the verification code;
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
3. Create an Email one-time passcode sign-up/sign-in user flow and associate
   the application with it.
4. Grant the API permissions required by your scenario.

Use only the tenant prefix. For `contoso.onmicrosoft.com`, pass `contoso`.

## Run

```shell
flutter run \
  --dart-define=ENTRA_CLIENT_ID=<application-client-id> \
  --dart-define=ENTRA_TENANT_SUBDOMAIN=<tenant-prefix>
```

The values above are public client configuration, not secrets. Do not add a
client secret to this example or any mobile application.

The iOS Runner already contains the MSAL keychain access-group entitlement.
Select your own development team when signing for a physical Apple device.

Microsoft references:

- [Prepare Android for native authentication](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app)
- [Run the iOS native-authentication sign-in sample](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in)
