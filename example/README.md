# Microsoft Entra External ID native-authentication example

This Flutter app implements the native-authentication flows in Microsoft's
samples. Material navigation separates them into five reproducible scenarios:

- **Email OTP** for passwordless sign-in and sign-up;
- **Password** for direct password sign-in and sign-up;
- **Attributes** for Email OTP sign-up with tenant-required profile data;
- **Password Reset** for the complete recovery continuation;
- **More** for explicit system-browser fallback and API configuration status.

The app can:

- restore a cached account;
- sign in with email/username and password or Email OTP;
- sign up with a password or Email OTP;
- collect tenant-defined required/custom attributes;
- reset a password with Email OTP and set a new password;
- submit or resend the verification code;
- acquire an API-scoped access token and force an MSAL cache refresh;
- continue through the official MSAL system browser when native auth returns
  `browserRequired`;
- automatically sign in after sign-up;
- sign out.

Android calls MSAL Native Auth directly. iOS calls
`MSALNativeAuthPublicClientApplication` through Swift Package Manager.

## External tenant setup

Before running the app, set up an **external tenant** as Microsoft requires:

1. Register an application and record its Application (client) ID.
2. Under **Authentication > Advanced settings**, enable both mobile/desktop
   public client flows and native authentication.
3. Create an Email one-time passcode or Email with password sign-up/sign-in user
   flow and associate the application with it. Enable self-service password
   reset for customer users when recovery is required.
4. Grant the API permissions required by your scenario.
5. Add a mobile/desktop redirect URI for browser fallback. Configure the same
   URI in the Android MSAL callback activity/intent filter and the iOS URL
   scheme, following Microsoft's platform setup guidance. The included iOS
   example uses `msauth.$(PRODUCT_BUNDLE_IDENTIFIER)://auth`.

Use only the tenant prefix. For `contoso.onmicrosoft.com`, pass `contoso`.

## Run

For local device testing, keep the tenant values in the ignored `.env.local`
file and export them before invoking Flutter:

```shell
set -a
source .env.local
set +a
```

```shell
flutter run \
  --dart-define=ENTRA_CLIENT_ID="$ENTRA_CLIENT_ID" \
  --dart-define=ENTRA_TENANT_SUBDOMAIN="$ENTRA_TENANT_SUBDOMAIN" \
  --dart-define=ENTRA_REDIRECT_URI="$ENTRA_REDIRECT_URI" \
  --dart-define=ENTRA_API_SCOPE="$ENTRA_API_SCOPE"
```

`ENTRA_API_SCOPE` is optional. Without it, MSAL requests its default OIDC
scopes. `ENTRA_REDIRECT_URI` is required for the system-browser fallback action.
Choose **Email OTP** or **Password** explicitly. Do not use an empty password to
select an authentication mechanism. The example renders required attributes
dynamically and reuses its code and password continuation screens for password
reset.

The client ID, tenant prefix, and scope are public client configuration, not
secrets. Do not add a client secret to this example or any mobile application.
Never print or persist the entered password, access token, or ID token.

For Android, the registered redirect URI has the form
`msauth://<package-name>/<url-encoded-signature-hash>`. Add a matching callback
activity to the host app manifest; the manifest path uses the unencoded hash:

```xml
<activity
    android:name="com.microsoft.identity.client.BrowserTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="msauth"
            android:host="&lt;package-name&gt;"
            android:path="/&lt;signature-hash&gt;" />
    </intent-filter>
</activity>
```

The redirect URI and callback activity must match the signing variant being
tested (debug, internal, or release). See Microsoft's [MSAL Android redirect
configuration](https://learn.microsoft.com/en-us/entra/msal/android/) for the
signature-hash commands.

The iOS Runner already contains the MSAL keychain access-group entitlement.
Select your own development team when signing for a physical Apple device.

Microsoft references:

- [Prepare Android for native authentication](https://learn.microsoft.com/en-us/entra/identity-platform/tutorial-native-authentication-prepare-android-app)
- [Run the iOS native-authentication sign-in sample](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-native-authentication-ios-sign-in)
- [Support native-authentication web fallback](https://learn.microsoft.com/en-us/entra/identity-platform/concept-native-authentication-web-fallback)
