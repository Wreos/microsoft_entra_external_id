# Implementation plan

Every stage has a validation gate. A stage is complete only when its checks
pass and the result is committed. A live-tenant test is never used as a
substitute for deterministic unit and contract tests.

## Stage 0 — Intent and market boundary

**Deliverables**

- Define the External ID-only target and custom-UI value proposition.
- Separate native authentication from browser-delegated MSAL flows.
- Record MVP scope, non-goals, security constraints, and success criteria.

**Validation gate**

- Cross-check the claims against current Microsoft Native Authentication docs.
- Confirm that browser fallback and shared security responsibility are explicit.

**Status:** complete. See `INTENT.md`.

## Stage 1 — Repository bootstrap

**Deliverables**

- Generate one Android/iOS Flutter plugin package with Kotlin and Swift.
- Use the OSS namespace `io.github.wreos.entra_external_id`.
- Replace template placeholders with project metadata and an MIT license.
- Add a typed Pigeon diagnostic channel without linking MSAL prematurely.
- Retain Dart, native, widget, and integration-test locations.
- Pin the Flutter 3.47.2 toolchain baseline and document native SDK candidates
  and deployment floors in `doc/STACK.md`.

**Validation gate**

- Generate Pigeon output from a checked-in schema.
- Run Dart formatting, Flutter analysis, and Flutter tests.
- Run Android unit tests and build the Android example.
- Run iOS tests/build when an iOS simulator and Xcode/SwiftPM environment are
  available.
- Confirm the generated Android and iOS projects match Flutter 3.47.2's current
  plugin template, except for documented package-specific decisions.
- Verify that no `com.example`, `TODO`, or `getPlatformVersion` template code
  remains.

**Status:** complete. See `doc/VALIDATION.md`. The iOS Runner starts on an
isolated simulator and the XCTest bundle compiles, but Xcode does not expose
that isolated device set as a test destination. XCTest execution remains a
required CI and release gate.

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

**Status:** Email OTP contract slice complete. Account/token, password,
attributes, MFA, cancellation, and correlation metadata remain in later slices.

## Stage 3 — Android initialization and sign-in slice

**Deliverables**

- Pin a supported MSAL Android version and document the minimum Android API.
- Create one native client per Flutter plugin instance.
- Implement initialization, current account, password sign-in, email-OTP
  sign-in, code submission/resend, token retrieval, and sign-out.

**Validation gate**

- Kotlin tests cover every mapped result and continuation.
- Gradle unit tests and the Android example build pass.
- A manual external-tenant smoke test passes for password and OTP sign-in.
- Logs contain no credentials, codes, tokens, continuation data, or PII.

**Status:** Email OTP implementation and deterministic build gate complete with
MSAL Android 8.4.2. Password/token APIs, complete native branch tests, and a
live-tenant smoke test are still open, so the full stage is not complete.

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

**Status:** Email OTP implementation, SwiftPM build-for-testing, and isolated
simulator app-launch gates complete with MSAL iOS 2.15.0. Runtime XCTest is
blocked by local Xcode destination discovery; password/token APIs, complete
delegate tests, and live-tenant smoke tests are still open, so the full stage
is not complete.

## Stage 5 — Sign-up, attributes, and password reset

**Deliverables**

- Implement password and OTP sign-up.
- Implement built-in/custom required attributes and validation errors.
- Implement self-service password reset and sign-in continuation.

**Validation gate**

- Shared Dart scenario tests pass on Android and iOS.
- Native tests cover every new result/delegate branch.
- Live-tenant tests cover sign-up, attribute collection, and password reset.

## Stage 6 — Advanced states and fallback

**Deliverables**

- Implement or explicitly reject MFA and strong-auth registration continuations.
- Implement typed browser fallback without embedding a WebView in the plugin.
- Define cancellation, timeout, app-background, and process-recreation behavior.

**Validation gate**

- Capability matrix documents parity and known platform limitations.
- Tests cover cancellation, stale continuations, duplicate submissions, engine
  detach, and multiple Flutter engines.

## Stage 7 — Security and release candidate

**Deliverables**

- Add a threat model, `SECURITY.md`, migration policy, and full integration docs.
- Add CI for Dart, Android, iOS, generated-code drift, and example builds.
- Prepare API docs and a prerelease package.

**Validation gate**

- Formatting, analysis, Dart/native/integration tests, dependency review, secret
  scanning, generated-code drift, and `flutter pub publish --dry-run` pass.
- At least one independent Flutter team completes integration without changing
  native bridge code.
- Publish only as a prerelease until both platforms pass the documented matrix.

**Status:** CI/CD infrastructure complete: immutable Action pins, Dart and
Pigeon quality gates, Android unit/build/emulator gates, iOS XCTest/simulator
gates, dependency review, targeted secret scanning, publish dry-run, weekly
dependency updates, and tag-gated draft GitHub releases are configured. The
threat model, complete API/integration documentation, independent-team trial,
live-tenant matrix, and prerelease publication remain open, so the stage is not
complete.

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
