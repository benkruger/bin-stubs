# Rust Standards

The Rust package is held by rustfmt, Clippy and cargo test under full line
coverage.

## The Rule

- `bin/format` rewrites the package with `cargo fmt`, and with `--check`
  runs `cargo fmt --check`, which fails on unformatted code.
- `bin/lint` runs Clippy on every target of every workspace member and
  fails on any warning; `bin/build` builds every member.
- Every Clippy lint runs at its default level or higher
  (`no-lint-exceptions.md`); the code changes until Clippy passes.
- `bin/test` runs every member's suite under `cargo llvm-cov` and fails on
  a failing test or below 100% line coverage of the workspace; with no
  rustup, it takes LLVM's tools from `llvm-cov` on `PATH` or Homebrew's
  `llvm`.
- `rust-toolchain.toml` pins the toolchain; for a numbered channel, outside
  CI, `bin/ci` fails unless that rustc is active.
- Trigger: any change to a Rust `bin/` script.
<!-- audited: 7285c931568d -->
