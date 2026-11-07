# bin-stubs

## What

Everything a repo needs before an agent codes in it:

1. **How to behave here**: `CLAUDE.md`.
2. **What the code must meet**: `.claude/rules/`.
3. **One gate that proves it**: `bin/ci`. Nothing is committed unless it passes.

Instructions without a gate are hopes. Wherever a standard can be checked, a script checks it.

The kit is a set of `bin` scripts, one folder per language, plus a starter for the repo root. `format` rewrites the files. `lint` catches mistakes. `build` proves it compiles. `test` runs the tests. `changed` runs format, lint, and the tests for the files since the last commit. `ci` runs all four on the whole app and writes the sentinel. `dependencies` is where versions change. The sentinel is the saved pass.

The root `bin/ci` runs the repo-level guards, then picks the apps and runs each app's `bin/ci`. The root `bin/changed` does the same with `bin/changed`.

## Why

No GitHub Actions. The check runs on your machine, before the commit. The scripts are separate so the agent can run one step without paying for the whole gate. `changed` is the fast loop while writing, because it skips the build. `ci` is the commit. The sentinel makes an unchanged app free the next time. A pass shows the step lines. A failure shows the step that broke.

## Set up a repo

1. Copy `bin/` into the repo root.
2. For each app, copy that language's `bin/` into the app folder. An app at the repo root goes in `bin/_root/`. Copy that language's `.claude/rules/` into the repo's `.claude/rules/`.
3. Copy the contents of `starter/` into the repo root: `CLAUDE.md`, `.claude/rules/`, `tests/run` and `tests/guards`. Put the project's name in the `CLAUDE.md` heading.
4. Ignore `.flow-states/`, `.claude/cost/`, and the dependency folders (`node_modules/`, `.venv/`, `vendor/`, `target/`, `.build/`).
5. Run `bin/ci` until it passes. From then on every commit goes through it.

## How

After an edit, the agent runs `changed`, or one step. It runs again until that command passes. Before the commit, it runs `ci`. A matching sentinel finishes at once. Otherwise the four steps run and a new sentinel is written. The commit happens when `ci` exits 0. Version changes go through `dependencies`, then `ci`.

## `CLAUDE.md` and rules

Both are written for the agent. No person needs to read them.

| File | Holds |
| --- | --- |
| `~/.claude/CLAUDE.md` | How the agent behaves in every repo: change control, verifying work, git, replies |
| `CLAUDE.md` | How the agent behaves in this repo: which scripts to run and when, which files need an explicit go |
| `.claude/rules/*.md` | What the code must meet: architecture invariants, test, lint, size and dependency standards. One topic per file |

- Sort by subject. About the agent's actions: `CLAUDE.md`. About the code: a rule. Say each thing once.
- Neither holds plan notes, command lists, maps of where things live, or anything the agent can read from the code. Those go stale and still get trusted.
- A rule leads with one H1 naming the constraint, then one line a reader can act on, then `## The Rule` with present-tense statements of what the code is, and where each one is checked.
- A rule that would die with the feature it mentions is documentation. Drop it.

The starter ships these rules. Each language folder adds `<language>-standards.md`, which states what its scripts enforce.

| Rule | Holds the code to |
| --- | --- |
| `no-lint-exceptions` | Every linter rule on. No suppression comments, no configuration that turns a rule off |
| `authored-file-size` | No text file over 65,536 bytes. Split by responsibility |
| `guard-tests` | Every standard has a check in `tests/guards`, and every cap is pinned |
| `script-standards` | Every bash script strict, executable, and shellcheck-clean |

Add one rule for each invariant of the app that the code alone does not explain.

## The gate

### The sentinel

| | |
| --- | --- |
| Remembers | The last commit, every change since that commit, and files not committed yet |
| Ignores | `.flow-states/`, `.venv/`, `node_modules/`, `vendor/`, `target/`, `.build/`, and symlinks |
| Written | After the four steps pass |
| Match | Exit 0. The app prints nothing |
| `--force` | Run the four steps, then write the sentinel |
| `--clean` | Delete the sentinel and exit |
| Failure | The old sentinel stays |

A root app (`bin/_root/`) leaves the other apps, `CLAUDE.md`, `.claude/`, `checks/`, and `tests/` out of its sentinel.

### `bin/changed`

1. No files changed since the last commit, and none waiting to be committed. Exit 0. No output.
2. Format the changed files, then lint them.
3. TypeScript, JavaScript, Python, and Rails: each changed source file needs a matching test. Those tests run. Each of those files must be 100/100. Rust and iOS format, lint, and test the changed files.
4. No build. No sentinel.

At the repo root, that same case prints `bin/changed: nothing dirty` and exits 0.

### `bin/ci`

1. Compare the app with the sentinel.
2. A match exits 0 and prints nothing.
3. When the sentinel is stale, or the command is `--force`, install first where the app has an installer. TypeScript runs `bun install`. JavaScript uses the package manager named by its lockfile. Python runs `uv sync`. Rails runs `bundle install` when gems are missing.
4. Format, lint, build, test. A terminal shows `bin/ci: [1/4] format /` through `test ✓`.
5. A failed step prints its log. The old sentinel stays.
6. When all four pass, a new sentinel is written.

### Which apps run

1. A dirty path inside an app selects that app.
2. `CLAUDE.md`, `README.md`, `.claude/`, `tests/`, and `checks/` select `bin/_root-tests` on `ci` and `test`, and `bin/_root-changed` on `changed`.
3. On `ci` and `test`, a selected app also selects `bin/_root-tests`, and that check runs first.
4. A path outside every app selects the root app when `bin/_root/` is present, and every app otherwise.
5. On `ci`, `format`, `lint`, `build`, and `test`, a clean tree selects every app and `bin/_root-tests`.
6. `dependencies` selects every app.
7. `--force` selects every app, and on `ci` and `test` it also selects `bin/_root-tests`.
8. A folder of scripts with no project file is not an app. The project file is a `Gemfile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `Package.swift`, or an Xcode project.

### Root scripts

| Script | What it does |
| --- | --- |
| `bin/ci` | Run `ci` for the selected apps |
| `bin/changed` | Run `changed` for the selected apps |
| `bin/format` | Run `format` for the selected apps |
| `bin/lint` | Run `lint` for the selected apps |
| `bin/build` | Run `build` for the selected apps |
| `bin/test` | Run `test` for the selected apps |
| `bin/dependencies` | Refresh dependencies in every app |
| `bin/_dispatch` | Pick the apps and run the phase |
| `bin/_root-tests` | Repo-level check for `ci` and `test`: runs `tests/run` |
| `bin/_root-changed` | Repo-level check for `changed`: runs `tests/run` |

### App scripts

| Script | What it does |
| --- | --- |
| `bin/ci` | The whole app. Uses the sentinel |
| `bin/changed` | Files changed since the last commit. No sentinel |
| `bin/format` | Format |
| `bin/lint` | Lint |
| `bin/build` | Build. Used by `bin/ci` |
| `bin/test` | Test |
| `bin/dependencies` | Refresh the lockfile and install it |

| App | Format | Lint | Build | Test |
| --- | --- | --- | --- | --- |
| TypeScript | Biome write | Biome check | `tsc` | `bun test`, 100/100 on changed sources |
| JavaScript | Biome write | Biome check | Package build, or `node --check` | Package test under c8, 100/100 on changed sources |
| Python | Ruff format | Ruff check | `compileall` | pytest, 100/100 on changed sources |
| Rails | None | RuboCop `-A`, Brakeman, markdownlint | Zeitwerk | `db:test:prepare`, RSpec, warnings fail |
| Rust | `cargo fmt` | Clippy | `cargo build` | `cargo test` |
| iOS | `swift-format` | `swift-format` lint | `swift build`, or `xcodebuild` | `swift test`, or `xcodebuild` with a 100% line bar |

### Summary

| Word | Meaning |
| --- | --- |
| `PASS` | The work ran and exited 0 |
| `SKIP` | The sentinel matched, or that app was not selected |
| `FAIL` | Exited non-zero |
| Exit code | The result. One `FAIL` fails the command |

## Guards

The app scripts check the code. `tests/guards` checks the standards themselves. `bin/_root-tests` runs `tests/run`, and `tests/run` runs the guards, so a broken standard fails the gate like a failing test.

| `tests/guards` fails when | Cap |
| --- | --- |
| A text file is too big. Generated lockfiles are exempt by name; other exemptions are exact paths | 65,536 bytes |
| A rule is too long, lacks one leading H1, has frontmatter or a "Why"/"History" heading, uses past-tense wording, or cites a missing rule | 40 lines, 8,000 characters |
| `CLAUDE.md` is too long, lacks one leading H1, or points at the rules | 400 lines, 12,000 characters |
| Any file silences a linter, `biome.json` turns rules off, `.rubocop.yml` disables a cop, or `Cargo.toml` allows a lint | |
| A bash script has a shellcheck finding, or an entry point is not executable or does not start with `set -euo pipefail` | |

When you add a check:

- **Pin every cap twice.** The constant lives in `tests/guards`; `tests/run` asserts its value. Raising a cap means editing both, never a quiet bump inside the change that wanted it.
- **Run scripts, don't read them.** Copy the script into a throwaway git repo, feed it a case, and assert its exit code and message.
- **Never write the token you ban.** Build it at run time, or the guard trips over its own text.
- **Prove the check fails.** Plant one violation, watch the gate go red, then remove it. This repo's `tests/run` keeps one planted violation per check.
- **A new standard lands with its check**, in the same change.

## Beyond the kit

The kit does not ship these. A repo ready for an agent has them too.

| Piece | Why |
| --- | --- |
| `.claude/settings.json` | Allow `Bash(bin/*)` so the gate runs without approval prompts. That rule matches only the relative form, so scripts are always run as `bin/ci`. Deny destructive git: `rebase`, `checkout`, `reset --hard`, `stash`, `clean`, force-push |
| Hooks | A `PreToolUse` hook that blocks calling the toolchain directly, so the agent goes through `bin/`. A `SessionStart` hook for cloud sessions that installs the toolchain and runs `bin/ci` |
| Pinned toolchain | `.nvmrc`, `.ruby-version`, `.python-version` or `rust-toolchain.toml`, checked before the gate runs |
| Lockfile | Versions move only through `bin/dependencies`. A vulnerable transitive dependency is lifted to the latest version, never pinned down |
| Commit tool | `flow-pro commit` runs `bin/ci` and commits only on a pass. Branch names have no `/` |
| End-to-end QA | A `bin/qa` that drives a fresh production build through the UI. The browser reaches only `127.0.0.1`. Timeouts and workers are pinned, nothing retries, and a console error fails the test |
| Test isolation | Every test resets the global state it touches. No test reaches the network or production data |
| Secrets | Never in the repo or the agent's output. A wrapper script injects them at run time and never prints them |
