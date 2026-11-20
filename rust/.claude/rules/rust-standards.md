# Rust Standards

The Rust package is held by rustfmt, Clippy and cargo test at full strength.

## The Rule

- `bin/format`, the first step of `bin/ci` and `bin/changed`, rewrites the
  package with `cargo fmt`.
- `bin/lint` runs Clippy on every target and fails on any warning.
- Every Clippy lint runs at its default level or higher
  (`no-lint-exceptions.md`); the code changes until Clippy passes.
- `bin/test` runs the whole suite with `cargo test`; one failing test fails
  `bin/ci` and `bin/changed`.
- `rust-toolchain.toml` pins the toolchain; for a numbered channel, `bin/ci`
  fails unless that rustc is active.
- Trigger: any change to a Rust `bin/` script.
<!-- audited: e2f9ee4bb8d1 -->
