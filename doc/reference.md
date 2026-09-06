# Reference

## Configuration

`NativeAuthConfiguration` requires:

| Field | Meaning |
| --- | --- |
| `clientId` | Application client ID from the external tenant. |
| `tenantSubdomain` | Tenant prefix, such as `contoso`. Do not use the full domain. |
| `redirectUri` | Optional registered URI for `signInWithBrowser`. |

## Client methods

| Method | Result |
| --- | --- |
| `initialize` | `NativeAuthInitialized` or `NativeAuthFailure`. |
| `getCurrentAccount` | Cached signed-in account or `NativeAuthSignedOut`. |
| `signIn` / `signInWithPassword` | A signed-in result, a code/password continuation, or failure. |
| `signUp` / `signUpWithPassword` | A code or attributes continuation, signed-in result, or failure. |
| `resetPassword` | A code/password continuation or failure. |
| `submitCode`, `submitPassword`, `submitAttributes` | The next state in the active flow. |
| `resendCode` | A new code-required state. |
| `getAccessToken` | A signed-in result with an access token. |
| `signInWithBrowser` | A signed-in result or failure from system-browser authentication. |
| `signOut` | `NativeAuthSignedOut` or failure. |

## States

| State | Meaning |
| --- | --- |
| `NativeAuthInitialized` | The native client is ready. |
| `NativeAuthSignedOut` | No account is present in the native cache. |
| `NativeAuthSignedIn` | An account, ID token, access token, granted scopes, and optional expiry are available. |
| `NativeAuthCodeRequired` | Submit a one-time code or resend the code. |
| `NativeAuthPasswordRequired` | Submit a password for the current continuation. |
| `NativeAuthAttributesRequired` | Collect and submit the tenant-provided attributes. |
| `NativeAuthFailure` | The operation failed. `browserRequired` tells the host whether it may start explicit browser fallback. |

Continuation IDs are opaque native-memory handles. Do not persist them. They
become invalid after completion, plugin detachment, or process termination.

## Platforms and native dependencies

| Platform | Native client | Requirement |
| --- | --- | --- |
| Android | `INativeAuthPublicClientApplication` | API 24+, Java 17, MSAL 8.4.2. |
| iOS | `MSALNativeAuthPublicClientApplication` | iOS 17+, Swift Package Manager, MSAL 2.15.0. |

Generated channels come from `pigeons/native_auth_api.dart`. Do not edit the
generated Dart, Kotlin, or Swift files by hand.
