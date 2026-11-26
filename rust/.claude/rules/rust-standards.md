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
- `bin/changed` runs `bin/format`, `bin/lint` and `bin/test` over the
  whole workspace when any file in the app changed since the last commit.
- `bin/dependencies` runs `cargo update`, then `cargo fetch`, as
  `packages.md` states; `packages_check` fails when
  `cargo fetch --offline --locked` fails: a crate is missing or
  `Cargo.lock` does not match `Cargo.toml`.
- `rust-toolchain.toml` pins the toolchain; for a numbered channel, outside
  CI, `bin/ci` fails unless that rustc is active. Every Rust script,
  `bin/dependencies` included, runs with `RUSTUP_AUTO_INSTALL=0`, so
  rustup never installs the pinned toolchain; `tests/run` fails when
  `bin/dependencies` or the scripts' shared toolchain setup leaves it
  unset.
- Trigger: any change to a Rust `bin/` script.
<!-- audited: c221b6aaac8f -->
