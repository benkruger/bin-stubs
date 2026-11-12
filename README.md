# bin-stubs

## What

Everything a repo needs before an agent codes in it:

1. **How to behave here**: `CLAUDE.md`.
2. **What the code must meet**: `.claude/rules/`.
3. **One gate that proves it**: `bin/ci`. Nothing is committed unless it
   passes.

Instructions without a gate are hopes. Wherever a standard can be checked, a
script checks it.

The kit is a set of `bin` scripts, one folder per language, plus a starter for
the repo root. `format` rewrites the files. `lint` catches mistakes. `build`
proves it compiles. `test` runs the tests. `changed` runs format, lint, and the
tests for the files since the last commit. `ci` runs all four on the whole app
and writes the sentinel. `dependencies` is where versions change. The sentinel
is the saved pass.

The root `bin/ci` runs the repo-level guards, then picks the apps and runs each
app's `bin/ci`. The root `bin/changed` does the same with `bin/changed`.

## Why

No GitHub Actions. The check runs on your machine, before the commit. The
scripts are separate so the agent can run one step without paying for the
whole gate. `changed` is the fast loop while writing, because it skips the
build. `ci` is the commit. The sentinel makes an unchanged app free the next
time. A pass shows the step lines. A failure shows the step that broke.

## Set up a repo

1. Copy `bin/` into the repo root.
2. For each app, copy that language's `bin/` into the app folder. An app at the
   repo root goes in `bin/_root/`. Copy that language's `.claude/rules/` into
   the repo's `.claude/rules/`.
3. Copy the contents of `starter/` into the repo root: `CLAUDE.md`,
   `.claude/rules/`, `.claude/settings.json`, `.claude/hooks/`, `tests/run`
   and `tests/guards`. Put the project's name in the `CLAUDE.md` heading.
4. Ignore `.flow-states/`, `.claude/cost/`, and the dependency folders
   (`node_modules/`, `.venv/`, `vendor/`, `target/`, `.build/`).
5. Install shellcheck, shfmt, markdownlint-cli2 and jq; the guards and the
   hooks need them.
6. Pin each app's toolchain (see "Pinned toolchain").
7. Run `bin/ci` until it passes. From then on every commit goes through it.

## How

After an edit, the agent runs `changed`, or one step. It runs again until that
command passes. Before the commit, it runs `ci`. A matching sentinel finishes
at once. Otherwise the four steps run and a new sentinel is written. The commit
happens when `ci` exits 0. Version changes go through `dependencies`, then
`ci`.

## `CLAUDE.md` and rules

Both are written for the agent. No person needs to read them.

- `~/.claude/CLAUDE.md`: how the agent behaves in every repo. Change control,
  verifying work, git, replies.
- `CLAUDE.md`: how the agent behaves in this repo. Which scripts to run and
  when, which files need an explicit go.
- `.claude/rules/*.md`: what the code must meet. Architecture invariants,
  test, lint, size and dependency standards. One topic per file.

Sort by subject. About the agent's actions: `CLAUDE.md`. About the code: a
rule. Say each thing once. Neither holds plan notes, command lists, maps of
where things live, or anything the agent can read from the code. Those go
stale and still get trusted.

A rule leads with one H1 naming the constraint, then one line a reader can act
on, then `## The Rule` with present-tense statements of what the code is, and
where each one is checked. A rule that would die with the feature it mentions
is documentation. Drop it.

The starter ships these rules:

- `no-lint-exceptions`: every linter rule on. No suppression comments, no
  configuration that turns a rule off.
- `authored-file-size`: no text file over 65,536 bytes. Split by
  responsibility.
- `guard-tests`: every standard has a check in `tests/guards`, and every cap
  is pinned.
- `script-standards`: every bash script strict, executable, formatted and
  shellcheck-clean.

Each language folder adds `<language>-standards.md`, which states what its
scripts enforce. Add one rule for each invariant of the app that the code
alone does not explain.

## The gate

### The sentinel

- **Remembers** the last commit, every change since that commit, and files
  not committed yet.
- **Ignores** `.flow-states/`, `.venv/`, `node_modules/`, `vendor/`,
  `target/`, `.build/`, and symlinks.
- **Is written** after the four steps pass.
- **A match** exits 0, and the app prints nothing.
- **`--force`** runs the four steps, then writes the sentinel.
- **`--clean`** deletes the sentinel and exits.
- **A failure** leaves the old sentinel in place.

A root app (`bin/_root/`) leaves the other apps, `CLAUDE.md`, `.claude/`,
`checks/`, and `tests/` out of its sentinel.

### `bin/changed`

1. No files changed since the last commit, and none waiting to be committed.
   Exit 0. No output.
2. Format the changed files, then lint them.
3. TypeScript, JavaScript, Python, and Rails: each changed source file needs a
   matching test. Those tests run. Each of those files must be 100/100. Rust
   and iOS format, lint, and test the changed files.
4. No build. No sentinel.

At the repo root, that same case prints `bin/changed: nothing dirty` and exits
0.

### `bin/ci`

1. Check the toolchain against its pin. A mismatch fails before anything
   else runs.
2. Compare the app with the sentinel. A match exits 0 and prints nothing.
3. When the sentinel is stale, or the command is `--force`, install first
   where the app has an installer. TypeScript runs `bun install`. JavaScript
   uses the package manager named by its lockfile. Python runs `uv sync`.
   Rails runs `bundle install` when gems are missing.
4. Format, lint, build, test. A terminal shows `bin/ci: [1/4] format /`
   through `test ✓`.
5. A failed step prints its log. The old sentinel stays.
6. When all four pass, a new sentinel is written.

### Which apps run

1. A dirty path inside an app selects that app.
2. `CLAUDE.md`, `README.md`, `.claude/`, `tests/`, and `checks/` select
   `bin/_root-tests` on `ci` and `test`, and `bin/_root-changed` on
   `changed`.
3. On `ci` and `test`, a selected app also selects `bin/_root-tests`, and that
   check runs first.
4. A path outside every app selects the root app when `bin/_root/` is present,
   and every app otherwise.
5. On `ci`, `format`, `lint`, `build`, and `test`, a clean tree selects every
   app and `bin/_root-tests`.
6. `dependencies` selects every app.
7. `--force` selects every app, and on `ci` and `test` it also selects
   `bin/_root-tests`.
8. A folder of scripts with no project file is not an app. The project file is
   a `Gemfile`, `package.json`, `pyproject.toml`, `Cargo.toml`,
   `Package.swift`, or an Xcode project.
9. `format` always runs `bin/_root-format` first, whatever is dirty.

### Root scripts

| Script              | What it does                         |
| ------------------- | ------------------------------------ |
| `bin/ci`            | Run `ci` for the selected apps       |
| `bin/changed`       | Run `changed` for the selected apps  |
| `bin/format`        | Run `format` for the selected apps   |
| `bin/lint`          | Run `lint` for the selected apps     |
| `bin/build`         | Run `build` for the selected apps    |
| `bin/test`          | Run `test` for the selected apps     |
| `bin/dependencies`  | Refresh dependencies in every app    |
| `bin/_dispatch`     | Pick the apps and run the phase      |
| `bin/_root-tests`   | Repo-level check for `ci` and `test` |
| `bin/_root-changed` | Repo-level check for `changed`       |
| `bin/_root-format`  | Repo-level format for `format`       |
| `bin/scan`          | Search the repo                      |

Both repo-level checks run `tests/run`. `bin/_root-format` rewrites every
bash script with `shfmt -i 2 -ci` and fixes every Markdown file with
markdownlint, so a formatting finding from the guards is fixed by
`bin/format`. `bin/scan` takes `refs <string>`
(matches, and the commits that added or removed them), `log <git-log-args>`,
`grep <rg-args>` (needs ripgrep) or `files <pathspec>`.

### App scripts

| Script             | What it does                                     |
| ------------------ | ------------------------------------------------ |
| `bin/ci`           | The whole app. Uses the sentinel                 |
| `bin/changed`      | Files changed since the last commit. No sentinel |
| `bin/format`       | Format                                           |
| `bin/lint`         | Lint                                             |
| `bin/build`        | Build. Used by `bin/ci`                          |
| `bin/test`         | Test                                             |
| `bin/dependencies` | Refresh the lockfile and install it              |
| `bin/open`         | Run the app on 127.0.0.1 and open it             |

TypeScript, JavaScript and Rails ship `bin/open`. TypeScript and JavaScript
run the `dev` script with `--host 127.0.0.1 --open`; Rails starts
`rails server` on `PORT` (default 3000) and opens the browser once it answers.

- **TypeScript**: Biome write, Biome check, `tsc`, then `bun test` with
  100/100 on changed sources.
- **JavaScript**: Biome write, Biome check, the package build or
  `node --check`, then the package test under c8 with 100/100 on changed
  sources.
- **Python**: Ruff format, Ruff check, `compileall`, then pytest with 100/100
  on changed sources.
- **Rails**: no formatter; RuboCop `-A`, Brakeman and markdownlint; Zeitwerk;
  then `db:test:prepare` when the app has a database, and Minitest through
  `rails test`, where warnings fail.
- **Rust**: `cargo fmt`, Clippy, `cargo build`, `cargo test`.
- **iOS**: `swift-format`, `swift-format` lint, `swift build` or
  `xcodebuild`, then `swift test` or `xcodebuild` with a 100% line bar.

### Summary

| Word      | Meaning                                            |
| --------- | -------------------------------------------------- |
| `PASS`    | The work ran and exited 0                          |
| `SKIP`    | The sentinel matched, or that app was not selected |
| `FAIL`    | Exited non-zero                                    |
| Exit code | The result. One `FAIL` fails the command           |

## Guards

The app scripts check the code. `tests/guards` checks the standards
themselves. `bin/_root-tests` runs `tests/run`, and `tests/run` runs the
guards, so a broken standard fails the gate like a failing test.

`tests/guards` fails when:

- A text file is over 65,536 bytes. Generated lockfiles are exempt by name;
  any other exemption is an exact path.
- A rule is over 40 lines or 8,000 characters, lacks one leading H1, has
  frontmatter or a "Why" or "History" heading, uses past-tense wording, or
  cites a missing rule.
- `CLAUDE.md` is over 400 lines or 12,000 characters, lacks one leading H1,
  or points at the rules.
- Any file silences a linter, `biome.json` turns rules off, `.rubocop.yml`
  disables a cop, or `Cargo.toml` allows a lint.
- A bash script has a shellcheck finding or is not formatted by
  `shfmt -i 2 -ci`, or an entry point is not executable or does not start
  with `set -euo pipefail`.
- A Markdown file breaks a markdownlint rule.
- `.claude/settings.json` is missing or invalid, does not allow `Bash(bin/*)`,
  does not deny destructive git, or does not wire both hooks.

When you add a check:

- **Pin every cap twice.** The constant lives in `tests/guards`; `tests/run`
  asserts its value. Raising a cap means editing both, never a quiet bump
  inside the change that wanted it.
- **Run scripts, don't read them.** Copy the script into a throwaway git
  repo, feed it a case, and assert its exit code and message.
- **Never write the token you ban.** Build it at run time, or the guard trips
  over its own text.
- **Prove the check fails.** Plant one violation, watch the gate go red, then
  remove it. This repo's `tests/run` keeps one planted violation per check.
- **A new standard lands with its check**, in the same change.

## Permissions and hooks

The starter's `.claude/settings.json` sets what the agent may run:

- **Allows** `Bash(bin/*)`, `Bash(*/bin/*)` and `Bash(tests/run)`, so the gate
  runs without approval prompts. These match the relative form, so scripts
  are always run as `bin/ci`.
- **Denies** destructive git: `commit` (commits go through `flow-pro commit`),
  `rebase`, `checkout`, `reset`, `stash`, `clean`, and force-push, with or
  without `git -C`.
- **`require-bin`** (`PreToolUse`) blocks a command that calls the toolchain
  directly (bun, Biome, Ruff, RuboCop, cargo, swift, `rails test` and the
  rest), anywhere in a compound command and through runners like `npx`,
  `bundle exec` and `uv run`. The agent is told to use the `bin/` script.
- **`session-start`** (`SessionStart`) runs `bin/ci` once in a cloud session,
  so the session starts from a known state. A local session is left alone.

The guards fail when the file is missing, invalid, or drops any of these.

## Pinned toolchain

Each app pins its toolchain in a file, and its `bin/ci` fails unless that
version is the one running. The check is skipped when `CI` is set.

- **TypeScript**: `.bun-version` must match `bun --version`.
- **JavaScript**: `.nvmrc`. `bin/ci` switches to it through nvm when nvm is
  installed, then requires it.
- **Python**: `.python-version`. uv must find an installed Python matching it.
- **Rails**: `.ruby-version` must match the active Ruby.
- **Rust**: `rust-toolchain.toml`. A numbered channel must match the active
  `rustc`; a named one such as `stable` is left to rustup.
- **iOS**: `.xcode-version` must match the selected Xcode.

A mismatch names the fix, such as `rbenv install 3.4.8`. The gate never
installs a toolchain itself.

## Beyond the kit

The kit does not ship these. A repo ready for an agent has them too.

- **Lockfile**: versions move only through `bin/dependencies`. A vulnerable
  transitive dependency is lifted to the latest version, never pinned down.
- **Commit tool**: `flow-pro commit` runs `bin/ci` and commits only on a
  pass. Branch names have no `/`.
- **End-to-end QA**: a `bin/qa` that drives a fresh production build through
  the UI. The browser reaches only `127.0.0.1`. Timeouts and workers are
  pinned, nothing retries, and a console error fails the test.
- **Test isolation**: every test resets the global state it touches. No test
  reaches the network or production data.
- **Secrets**: never in the repo or the agent's output. A wrapper script
  injects them at run time and never prints them.
