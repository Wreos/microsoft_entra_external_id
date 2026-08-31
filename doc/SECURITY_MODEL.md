# Security model

`microsoft_entra_external_id` is a bridge between application-owned Flutter UI
and Microsoft-owned Native Authentication SDKs. It does not implement OAuth or
OpenID Connect in Dart.

## Trust boundaries

- The host application owns UI, input validation, accessibility, screen
  privacy, telemetry, and secure delivery of access tokens to the intended API.
- The plugin validates the public configuration, maps typed flow states, and
  keeps native continuation objects in memory per plugin instance.
- MSAL owns protocol execution, native account state, refresh tokens, token
  renewal, and protected native cache behavior.
- Microsoft Entra External ID owns tenant policy, credentials, challenges,
  token issuance, and fallback requirements.

## Sensitive data

Passwords and Email OTP values cross the Dart/native boundary only when the
host explicitly submits them. The plugin does not persist them. Continuation
identifiers are opaque, in-memory handles and become invalid after completion,
plugin detachment, or process termination.

Access and ID tokens cross into Dart only in explicit authentication results.
Refresh tokens never cross into Dart and remain in the native MSAL cache. Host
applications must not log or persist credentials, codes, continuation handles,
access tokens, or ID tokens.

## Browser fallback

`NativeAuthFailure.browserRequired == true` means the native flow cannot
continue. The plugin does not open an embedded WebView or silently switch
authentication mechanisms. The host may start a separate system-browser flow
after explaining the transition to the user.

Ordinary SDK errors are returned as failures and must not trigger an automatic
fallback. This prevents outages or malformed configuration from unexpectedly
changing the authentication surface.

## Threats and mitigations

| Threat | Mitigation |
| --- | --- |
| Credentials or tokens appear in logs | Native results are mapped to sanitized states; release checks reject common secret patterns; hosts are explicitly required not to log sensitive values. |
| Refresh-token theft from Dart storage | Refresh tokens are never exposed by the public or Pigeon contracts and remain in MSAL's native cache. |
| Reusing or persisting an interactive continuation | Handles refer only to in-memory native state and are invalidated after use, detach, or process death. |
| UI spoofing or insecure custom UI | The host owns the UI and must apply platform security, accessibility, privacy, and anti-overlay practices appropriate to its risk profile. |
| Silent downgrade to browser/WebView auth | Browser-required is an explicit typed signal; no WebView or automatic browser fallback is implemented. |
| Token sent to the wrong API | The host requests explicit scopes and must send the access token only to the matching HTTPS resource server. |
| Cross-engine state leakage | Each Flutter plugin instance owns one native client and releases native state when detached. |

## Known gaps

Password sign-up, required attributes, password reset, MFA, strong-auth
registration, browser-fallback execution, and process-recreation recovery are
not implemented in the first development release. See `doc/VALIDATION.md` for
the live-test matrix and do not infer production readiness from compilation or
deterministic tests alone.
