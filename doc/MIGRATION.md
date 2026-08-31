# Migration policy

The package follows semantic versioning, but the public API is experimental
until `1.0.0`.

- Development prereleases such as `0.1.0-dev.1` may change APIs between
  versions when native MSAL behavior or the typed state model requires it.
- Every published version records user-visible changes in `CHANGELOG.md`.
- Breaking changes in later `0.x` releases will include a migration note and,
  when practical, a deprecation window.
- Native SDK version changes are never silent: Android and iOS pins are exact,
  documented, and must pass package CI plus separate device/live-tenant gates.
- A stable `1.0.0` release requires a documented Android/iOS capability matrix
  and migration path from the latest `0.x` release.

Applications should pin a specific prerelease while evaluating the plugin and
review the changelog before upgrading. Do not use an unconstrained dependency
range for a production application during the preview period.
