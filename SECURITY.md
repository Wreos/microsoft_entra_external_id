# Security policy

## Supported versions

The latest published `0.x` development release receives security fixes on a
best-effort basis. Older development versions are not supported. This package
has not reached a stable `1.0.0` API or production-readiness guarantee.

## Reporting a vulnerability

Do not open a public issue with exploit details, credentials, tenant data,
tokens, continuation identifiers, or personally identifiable information.

Use GitHub's private vulnerability-reporting form in the repository Security
tab. Include the affected package version and platform, impact, minimal
reproduction steps, and a proposed remediation when available. Use synthetic
tenant data only.

If the private form is unavailable, open a public issue containing only a
request for a private maintainer contact channel. Do not include vulnerability
details in that issue.

## Scope

Reports are especially useful for credential or token exposure, unsafe native
cache handling, continuation reuse, authentication-state confusion, logging of
sensitive values, browser-fallback confusion, and Android/iOS bridge behavior
that differs from the documented contract.

Microsoft Entra service or MSAL vulnerabilities should also be reported through
Microsoft's security-response process. This project is unofficial and cannot
change Microsoft's service or SDK behavior.
