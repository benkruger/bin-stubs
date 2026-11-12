# Rust Standards

The Rust package is held by rustfmt, Clippy and cargo test at full strength.

## The Rule

- `cargo fmt` formats the package.
- Clippy lints every target, and every warning is an error.
- No lint is allowed in code or in `Cargo.toml` (`no-lint-exceptions.md`);
  the code changes until Clippy passes.
- `cargo test` runs the whole suite.
- `rust-toolchain.toml` pins the toolchain; for a numbered channel, `bin/ci`
  fails unless that rustc is active.
