# Architecture and security

The package keeps the authentication boundary small. Flutter owns screens,
input validation, accessibility, and delivery of access tokens to its API. MSAL
owns the authentication protocol, native account cache, token renewal, and
refresh tokens. Microsoft Entra External ID owns tenant policy and credentials.

The Dart API exposes typed states instead of Android or iOS SDK objects. Code,
password, and attributes are submitted only when the app calls a continuation
method. Continuation handles stay in native memory and are never valid after a
completed flow or process loss.

Refresh tokens never cross into Dart. Access and ID tokens appear only in an
explicit signed-in result. Host apps must not log or persist credentials, codes,
continuations, or tokens.

Browser fallback is separate from native authentication. `browserRequired`
means the tenant requires a system-browser flow. The host decides whether to
call `signInWithBrowser`; the plugin does not open an embedded WebView or change
authentication methods after an ordinary error.

MFA, strong-auth registration, and process-recreation recovery are not
implemented.
