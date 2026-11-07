# TypeScript Standards

The TypeScript app is held by Biome, `tsc` and `bun test` at full strength.

## The Rule

- Every source `src/<path>.ts` (or `.tsx`) has its twin
  `tests/<path>.test.ts`. `bin/changed` and `bin/test` fail a changed source
  with no twin.
- Every changed source is at 100% functions and lines; a changed test holds
  its source to the same bar.
- Biome formats and lints every file; `biome.json` keeps every rule on
  (`no-lint-exceptions.md`).
- `bin/build` type-checks the whole app with `tsc`.
