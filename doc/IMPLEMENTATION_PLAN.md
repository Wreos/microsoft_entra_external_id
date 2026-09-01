# Implementation plan

Every stage has a validation gate. A stage is complete only when its checks
pass and the result is committed. A live-tenant test is never used as a
substitute for deterministic unit and contract tests.

## Stage 0 — Intent and market boundary

**Deliverables**

- Define the External ID-only target and custom-UI value proposition.
- Separate native authentication from browser-delegated MSAL flows.
- Record initial scope, non-goals, security constraints, and success criteria.

**Validation gate**

- Cross-check the claims against current Microsoft Native Authentication docs.
- Confirm that browser fallback and shared security responsibility are explicit.

**Status:** complete. See `INTENT.md`.

## Stage 1 — Repository bootstrap

**Deliverables**

- Generate one Android/iOS Flutter plugin package with Kotlin and Swift.
- Use the OSS namespace `io.github.wreos.microsoft_entra_external_id`.
- Replace template placeholders with project metadata and an MIT license.
- Add a typed Pigeon diagnostic channel without linking MSAL prematurely.
- Retain Dart, native, widget, and integration-test locations.
- Pin the Flutter 3.47.2 toolchain baseline and document native SDK candidates
  and deployment floors in `doc/STACK.md`.

**Validation gate**

- Generate Pigeon output from a checked-in schema.
- Run Dart formatting, Flutter analysis, and Flutter tests.
- Run Android unit tests in CI and device integration tests as a manual gate.
- Run iOS tests when an iOS simulator and Xcode/SwiftPM environment are
  available.
- Confirm the generated Android and iOS projects match Flutter 3.47.2's current
  plugin template, except for documented package-specific decisions.
- Verify that no `com.example`, `TODO`, or `getPlatformVersion` template code
  remains.

**Status:** complete. See `doc/VALIDATION.md`. The iOS Runner starts on an
isolated simulator and the XCTest bundle compiles, but Xcode does not expose
that isolated device set as a test destination. XCTest execution remains a
manual release gate.

## Stage 2 — Cross-platform contract spike

**Deliverables**

- Define public Dart configuration, account, token, error, and flow-state models.
- Model completed, code-required, password-required, attributes-required,
  MFA-required, strong-auth-registration-required, browser-fallback, cancelled,
  and failed outcomes.
- Keep native MSAL result and delegate objects behind internal adapters.
- Define opaque in-memory continuation identifiers and lifecycle rules.

**Validation gate**

- Contract tests replay representative Android result objects and iOS delegate
  callbacks into the same Dart states.
- No Pigeon-generated type appears in the public API.
- No password, one-time code, token, or continuation can be serialized by a
  public model accidentally.

**Status:** Email OTP and password sign-in, sign-up attributes, password reset,
account, ID/access-token, scopes, expiry, and native-cache refresh contract
slices are complete. MFA, cancellation, and correlation metadata remain in
later slices.

## Stage 3 — Android initialization and sign-in slice

**Deliverables**

- Pin a supported MSAL Android version and document the minimum Android API.
- Create one native client per Flutter plugin instance.
- Implement initialization, current account, password sign-in, email-OTP
  sign-in, code submission/resend, token retrieval, and sign-out.

**Validation gate**

- Kotlin tests cover every mapped result and continuation.
- Gradle unit tests and Android emulator integration pass.
- A manual external-tenant smoke test passes for password and OTP sign-in.
- Logs contain no credentials, codes, tokens, continuation data, or PII.

**Status:** Email OTP and password sign-in plus token APIs are implemented with
MSAL Android 8.4.2. Deterministic gates and the physical-device Email OTP
live-tenant smoke test are complete. Password/API-scoped-token live-tenant
validation and complete native branch tests are still open, so the full stage
is not complete.

## Stage 4 — iOS parity for the sign-in slice

**Deliverables**

- Pin a supported MSAL iOS version and document the minimum iOS version and
  keychain requirements.
- Implement the Stage 3 behaviors through Swift delegates and continuations.

**Validation gate**

- XCTest covers every mapped delegate callback and continuation.
- Swift Package Manager integration compiles without a CocoaPods fallback.
- The iOS example and integration tests pass on a simulator.
- The same live-tenant password and OTP scenarios pass as on Android.

**Status:** Email OTP and password sign-in plus token APIs are implemented with
MSAL iOS 2.15.0. SwiftPM compilation covers the new delegates and native-cache
token adapter. Runtime XCTest is blocked locally by simulator infrastructure;
password/API-scoped-token live-tenant validation, complete delegate tests, and
the iOS live-tenant smoke tests are still open, so the full stage is not
complete.

## Stage 5 — Sign-up, attributes, and password reset

**Deliverables**

- Implement password and OTP sign-up.
- Implement built-in/custom required attributes and validation errors.
- Implement self-service password reset and sign-in continuation.

**Validation gate**

- Shared Dart scenario tests pass on Android and iOS.
- Native tests cover every new result/delegate branch.
- Live-tenant tests cover sign-up, attribute collection, and password reset.

**Status:** Password and Email OTP sign-up, required/custom attribute
continuations, self-service password reset, automatic sign-in after both
flows, and deterministic Dart/Android/iOS compilation gates are complete. The
physical-device and iOS live-tenant scenarios remain open and are tracked in
`doc/VALIDATION.md`.

## Stage 6 — Advanced states and fallback

**Deliverables**

- Implement or explicitly reject MFA and strong-auth registration continuations.
- Implement typed, explicit system-browser fallback without embedding a WebView
  in the plugin. **Complete:** `signInWithBrowser(...)` delegates to native
  MSAL interactive acquisition on Android and iOS.
- Define cancellation, timeout, app-background, and process-recreation behavior.

**Validation gate**

- Capability matrix documents parity and known platform limitations.
- Tests cover cancellation, stale continuations, duplicate submissions, engine
  detach, and multiple Flutter engines.

**Status:** The browser fallback bridge is implemented and package/native
compilation gates pass. Live-tenant redirect/callback validation and the
remaining MFA/strong-auth states are still open.

## Stage 7 — Security and release candidate

**Deliverables**

- Add a threat model, `SECURITY.md`, migration policy, and full integration docs.
- Add package-scoped CI for Dart, Android, iOS, and generated-code drift.
- Prepare API docs and a prerelease package.

**Validation gate**

- Formatting, analysis, Dart/native tests, dependency review, secret scanning,
  generated-code drift, and `flutter pub publish --dry-run` pass. Device and
  live-tenant tests pass as separate release gates.
- At least one independent Flutter team completes integration without changing
  native bridge code.
- Publish only as a prerelease until both platforms pass the documented matrix.

**Status:** CI/CD infrastructure complete: immutable Action pins, Dart and
Pigeon quality gates, Android plugin unit tests, iOS plugin-target compilation,
dependency review, targeted secret scanning, publish dry-run, weekly dependency
updates, and tag-gated draft GitHub releases are configured. CI does not build
or run the example app. The threat model, security-reporting path, migration
policy, and initial API/integration documentation are complete. The
`0.1.0-dev.1` development preview is published on pub.dev with a matching
public GitHub prerelease. The independent-team trial and live-tenant matrix
remain open, so the full stage is not complete. Those open parity gates block a
stable release; they are documented limitations rather than hidden blockers
for the published development preview.

## Stage 8 — Native SDK parity roadmap

The Flutter API targets flow-level parity, not a one-to-one copy of every MSAL
class and delegate. Native clients, delegate objects, refresh tokens, and
continuation data remain private to the platform implementation. Experimental
native APIs are not adopted until Microsoft marks them production-ready.

### Milestone 8.1 — Validate the implemented core

**Deliverables**

- Complete live-tenant password sign-in, password sign-up, required/custom
  attributes, password reset, API scopes, cache refresh, and sign-out on
  Android and iOS.
- Complete live system-browser redirect, callback, cancellation, and cache
  hand-off tests on both platforms.
- Add native iOS tests for every stable delegate branch already bridged by the
  plugin.

**Validation gate**

- The same account-flow matrix passes on a physical Android device and an iOS
  simulator or device.
- Tokens, credentials, one-time codes, and continuation data do not appear in
  logs, fixtures, screenshots, or persisted test output.

### Milestone 8.2 — Harden the cross-platform contract

**Deliverables**

- Add a typed cancellation result and normalize native error categories without
  exposing raw native result objects.
- Propagate safe correlation metadata for diagnostics without including PII or
  tokens.
- Define and test duplicate submission, stale continuation, overlapping flow,
  reinitialization, engine-detach, multiple-engine, app-background, and process
  recreation behavior.
- Remove the temporary Android Gradle old-DSL compatibility switch before its
  removal in Android Gradle Plugin 10.

**Validation gate**

- Shared Dart contract tests and native branch tests cover every documented
  terminal and continuation state.
- Lifecycle and concurrency tests cannot reuse a completed, detached, or
  otherwise stale continuation.

### Milestone 8.3 — Multi-factor authentication

**Deliverables**

- Add an explicit native-auth capability configuration for MFA only when the
  corresponding Flutter states are implemented.
- Model available email/SMS authentication methods, method selection,
  challenge request/resend, code submission, cancellation, and completion.
- Preserve requested API scopes through the MFA continuation and final token
  result.

**Validation gate**

- Android and iOS tests replay equivalent MFA-required flows into the same Dart
  states.
- Live-tenant email and SMS MFA scenarios pass on both platforms.

### Milestone 8.4 — Strong-auth method registration

**Deliverables**

- Add typed just-in-time registration states for the email/SMS methods exposed
  by the stable native SDKs.
- Implement method selection, challenge, resend, verification, cancellation,
  and post-registration continuation.
- Enable the native registration capability only after the complete flow is
  bridged on both platforms.

**Validation gate**

- Android and iOS produce the same Flutter-visible registration flow.
- New-account and policy-triggered live-tenant registration scenarios pass.

### Milestone 8.5 — Advanced authorization requests

**Deliverables**

- Bridge claims requests/authentication context through sign-in, automatic
  sign-in, and access-token acquisition without exposing platform SDK types.
- Add browser-fallback options required for federated identity providers,
  starting with domain hint and a deliberately small prompt policy.
- Document which options apply to native authentication and which restart the
  flow through the system browser.

**Validation gate**

- Claims challenges and federated browser hand-off pass deterministic contract
  tests and live-tenant tests on both platforms.
- Ordinary native SDK failures never trigger an implicit browser switch.

### Intentionally not bridged

- Refresh tokens, native cache objects, native client/delegate instances, and
  raw continuation objects.
- Client secrets, arbitrary authorities outside an External ID tenant, embedded
  WebViews, and a Dart OAuth implementation.
- Tenant administration and profile editing through Microsoft Graph; those are
  separate server/admin responsibilities rather than Native Authentication SDK
  flows.
- Experimental iOS server-driven APIs until Microsoft documents them as stable
  for production use.

## Working rules

- Use official Flutter and Microsoft documentation as the baseline.
- Treat MSAL Native Authentication as an architectural invariant. Android must
  use `INativeAuthPublicClientApplication`; iOS must use
  `MSALNativeAuthPublicClientApplication` and its delegate states. Browser-based
  interactive MSAL is fallback, never the core implementation.
- Pin native SDK versions; do not use floating versions such as `6.+`.
- Keep generated Pigeon code internal and regenerate all languages together.
- Add a failing regression test before fixing a discovered mapping bug.
- Never advance a stage while its validation gate is red.
