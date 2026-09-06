# How-to guides

## Complete Email OTP sign-in or sign-up

Start sign-in or sign-up without a password. When the result is
`NativeAuthCodeRequired`, show a code field and call `submitCode`. Use
`resendCode` only with the current code-required state.

```dart
final state = await entra.signIn(email);
if (state case NativeAuthCodeRequired()) {
  final completed = await entra.submitCode(state, code);
}
```

The same pattern applies to `signUp(email)`. Clear the code field after each
submission.

## Collect tenant-required attributes

`signUp` can return `NativeAuthAttributesRequired`. Render the
`requiredAttributes` supplied by the tenant, then pass their string values to
`submitAttributes`. If the next state lists `invalidAttributeNames`, show those
field errors and ask for corrected values.

```dart
final state = await entra.signUp(email);
if (state case NativeAuthAttributesRequired()) {
  final completed = await entra.submitAttributes(
    state,
    {'displayName': displayName},
  );
}
```

## Reset a password

Call `resetPassword(email)`. It returns the same typed code and password states
as sign-in. Check `state.operation == NativeAuthOperation.passwordReset` when
your UI needs to distinguish the recovery flow.

## Get or refresh an access token

Call `getAccessToken` after sign-in. MSAL uses its native cache and refreshes
expired access tokens. Set `forceRefresh` only when your app must bypass a
valid cached token.

```dart
final tokenState = await entra.getAccessToken(
  scopes: const ['api://your-api-client-id/access_as_user'],
  forceRefresh: true,
);
```

Refresh tokens never enter Dart.

## Continue in the system browser

When a native operation returns `NativeAuthFailure(browserRequired: true)`,
explain the transition and call `signInWithBrowser`. Pass a registered redirect
URI at initialization and at least one delegated resource scope. MSAL adds its
OpenID Connect scopes itself.

```dart
final browserState = await entra.signInWithBrowser(
  loginHint: email,
  scopes: const ['api://your-api-client-id/access_as_user'],
);
```

Do not switch to browser authentication for ordinary failures.

## Sign out

Call `signOut()` to remove the current account from the native MSAL cache.
