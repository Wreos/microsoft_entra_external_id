# Migration policy

The package follows semantic versioning. Its public API may change before
`1.0.0`.

- `0.x` releases may change APIs when native MSAL behavior or the typed state
  model requires it.
- Every published version records user-visible changes in `CHANGELOG.md`.
- Breaking changes in later `0.x` releases will include a migration note and,
  when practical, a deprecation window.
- Android and iOS SDK pins are exact and documented. A version change must pass
  package CI plus separate device and live-tenant gates.
- A stable `1.0.0` release requires a documented Android/iOS capability matrix
  and migration path from the latest `0.x` release.

Applications should pin a specific version and review the changelog before
upgrading. Do not use an unconstrained dependency range in production.
