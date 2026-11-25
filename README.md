# bin-stubs

## What

Everything a repo needs before an agent codes in it:

1. **How to behave here**: `CLAUDE.md`.
2. **What the code must meet**: `.claude/rules/`.
3. **One gate that proves it**: `bin/ci`. Nothing is committed unless it
   passes.

Instructions without a gate are hopes. Wherever a standard can be checked, a
script checks it.

The kit is one root `bin/` holding a folder of scripts per language
(`bin/_typescript/`, `bin/_javascript/`, `bin/_python/`, `bin/_rails/`,
`bin/_rust/`, `bin/_ios/`, `bin/_shell/`), plus a starter for the repo root.
`format` rewrites the files. `lint` catches mistakes. `build`
proves it compiles. `test` runs the tests. `changed` runs format, lint, and the
tests for the files since the last commit. `ci` runs all four on the whole app
and writes the sentinel. `dependencies` is where versions change. The sentinel
is the saved pass.

The root `bin/ci` runs the repo-level guards, then picks the apps and runs its
language's `ci` on each one. The root `bin/changed` does the same with
`changed`. An app holds no gate scripts of its own.

## Why

No GitHub Actions. The check runs on your machine, before the commit. The
scripts are separate so the agent can run one step without paying for the
whole gate. `changed` is the fast loop while writing, because it skips the
build. `ci` is the commit. The sentinel makes an unchanged app free the next
time. A pass shows the step lines. A failure shows the step that broke.

## Set up a repo

1. Copy `bin/` into the repo root. It runs every app, including one at the
   repo root; an app folder gets no scripts.
2. For each app's language, copy that language's `.claude/rules/` into the
   repo's `.claude/rules/`.
3. Copy the contents of `starter/` into the repo root: `CLAUDE.md`,
   `.claude/rules/`, `.claude/settings.json`, `.claude/hooks/`,
   `.githooks/`, `tests/run` and `tests/guards`. Put the project's name in
   the `CLAUDE.md` heading. Turn on the commit hook in each clone with
   `git config core.hooksPath .githooks`.
4. Ignore `.flow-states/`, `.worktrees/` (`bin/start` refuses without it),
   `.claude/cost/`, the dependency folders (`node_modules/`, `.venv/`,
   `vendor/`, `target/`, `.build/`) and build and coverage output
   (`dist/`, `build/`, `coverage/`).
5. Install shellcheck, shfmt, markdownlint-cli2 and jq; the guards and the
   hooks need them. Install Claude Code; `bin/commit` runs `claude` to
   review changed rules. A Rust app also needs `cargo-llvm-cov`
   (`cargo install cargo-llvm-cov`) and LLVM's tools: `llvm-tools-preview`
   under `components` in `rust-toolchain.toml` with rustup, or
   `brew install llvm` without it.
6. Pin each app's toolchain (see "Pinned toolchain").
7. Run `bin/ci` until it passes. From then on every commit goes through
   `bin/commit`, which runs it.

## How

After an edit, the agent runs `changed`, or one step. It runs again until that
command passes. Before the commit, it runs `ci`. A matching sentinel finishes
at once. Otherwise the four steps run at the same time, each failing step is
reported, and a new sentinel is written when all four pass.
`bin/commit` commits only when `ci` exits 0. Version changes go through
`dependencies`, then `ci`.

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

- `no-lint-exceptions`: every linter rule on. No suppression comments, and
  configuration only turns rules on or up, except that RuboCop's
  `Style/Documentation`, which only a comment satisfies, may be off.
- `no-comments`: no comment in any code file; only lines a tool reads stay.
- `authored-file-size`: no text file over 65,536 bytes. Split by
  responsibility.
- `guard-tests`: every standard has a check in `tests/guards`, and every cap
  is pinned.
- `script-standards`: every bash script strict, executable, formatted and
  shellcheck-clean.
- `dependency-pins`: a dependency held back, overridden or patched lands
  with a dated check in `checks/`, revisited within 30 days.
- `rule-authoring`: how a rule is written, and every rule edit reviewed and
  stamped through `bin/commit`.
- `claude-md`: `CLAUDE.md` stays short and never points at the rules.
- `every-test-runs`: no test is skipped, focused, left as todo or expected
  to fail.
- `test-time-limits`: every suite runs on its runner's default time limit;
  only one test at a time may carry a fixed number of its own.
- `full-coverage`: no coverage config narrows what is measured or lowers
  the 100% bar.
- `build-output`: build and coverage output stays out of git.
- `gate-scripts`: one copy of each gate script, in the root `bin/`, runs
  every app; an app holds none of its own.
- `ci-time`: an app's full `bin/ci` stays within 20% of its last time on
  each machine.
- `packages`: only `bin/dependencies` installs packages; every other script
  fails with "run bin/dependencies" when they are missing.

Each language folder adds `<language>-standards.md`, which states what its
scripts enforce. Add one rule for each invariant of the app that the code
alone does not explain.

## The gate

### The sentinel

- **Remembers** the content of the app's files as they are on disk,
  committed or not, with each file's mode and each symlink's target, and
  the scripts that check the app: its language's folder and `bin/lib/`.
  Committing changes nothing it remembers, so a commit keeps the pass.
- **Ignores** files git ignores, untracked files under `.flow-states/`,
  `.venv/`, `node_modules/`, `vendor/`, `target/` and `.build/`, and
  `.ci-timeout`.
- **Is written** after the four steps pass, holding the files as they were
  when the run started, so a file changed during the run is checked again.
- **A match** exits 0, and the app prints nothing.
- **`--force`** runs the four steps, then writes the sentinel.
- **`--clean`** deletes the sentinel and exits.
- **A failure** leaves the old sentinel in place.
- **Each step** that passes also saves its own sentinel, so a rerun on the
  same tree skips the steps that passed and reruns the ones that failed.
  `--force` ignores those, and `--clean` deletes them too.

A root app (a project file at the repo root) leaves the other apps,
`CLAUDE.md`, `.claude/` and `checks/` out of its sentinel; its own tests
live in `tests/`, so a change there runs it along with the repo-level
suite.

### `bin/changed`

1. List the files changed since the last commit and the ones not committed
   yet, once. `bin/changed --files` prints that list. Every script that works
   file by file reads it when given no paths.
2. An empty list exits 0. No output.
3. Pass the list to `format`, then to `lint`. Rust and iOS format and lint the
   whole package.
4. TypeScript, JavaScript, Python, and Rails: each changed source file needs a
   matching test. Those tests run. Each of those files must be 100% covered. Rust
   and iOS run the whole suite.
5. No build. No sentinel.

At the repo root, that same case prints `bin/changed: nothing dirty` and exits
0.

### `bin/ci`

1. Check the toolchain against its pin. A mismatch fails before anything
   else runs.
2. Compare the app with the sentinel. A match exits 0 and prints nothing.
3. When the sentinel is stale, or the command is `--force`, check that the
   app's packages are installed and match its manifest and lockfile; when
   they don't, fail with "run bin/dependencies". No script but
   `bin/dependencies` installs anything. TypeScript and JavaScript then
   fail on any moderate or worse audit advisory.
4. Format, lint, build, test, each over the whole app. A terminal shows
   `bin/ci: [1/4] format /` through `test ✓`. The format step only checks:
   an unformatted file fails it and nothing is rewritten. `bin/format` and
   `bin/changed` do the rewriting.
5. A failed step prints its log. The old sentinel stays. In TypeScript and
   JavaScript, a step that exits 0 still fails when its output has
   `npm warn`, `DeprecationWarning` or a line starting `Warning:`.
6. When all four pass, a new sentinel is written.

### Time ratchet

Each app commits a `.ci-timeout` with one `<host> <seconds>` line per
machine. After a root `bin/ci` runs all four of an app's steps and they
pass, `bin/_ci-timeout` compares the time with that machine's line. A run
more than 20% and at least 5 seconds over it fails, keeps the line, and
drops the app's sentinels, so the next run checks it again. Any other pass
writes its time, except on `main`, where the line is kept. The file is left
out of the sentinel and of what counts as dirty.

### `bin/commit`

`bin/commit <branch> <msgfile>` is how every commit lands. The message file
comes from `mktemp /tmp/flow-commit-msg.XXXXXX`; any other file is refused.
The branch has no `/`.

1. Work in `.worktrees/<branch>` when it exists, otherwise the repo root,
   and refuse unless that checkout is on `<branch>`.
2. When rule files changed, a separate Claude session reviews them against
   `rule-authoring.md`; a file that passed before is judged only on its
   changed lines. Claude fixes only the files a finding names, never a new
   one. After each fix a review checks that the earlier findings are gone
   and judges only the lines the fix changed, until it passes. When a round
   brings back the same findings as the one before, or after ten rounds,
   the commit is refused, naming the folder under `.flow-states/` that
   holds every round. A clean review stamps each file with
   `bin/stamp-rules`. Without `claude` the review is skipped, and the guards
   fail the unstamped rule.
3. Run `bin/ci` for at most `FLOW_CI_TIMEOUT_MS` milliseconds. Unset, the
   bound is five minutes until the repo holds a `.ci-timeout`; from then on
   the time ratchet bounds each app instead.
4. Stage everything. Nothing staged refuses the commit.
5. Commit, then `git push origin HEAD:<branch>`; `--no-push` before the
   branch commits without pushing.
6. Print one JSON line: `{"status":"ok","sha":…}`, or the step that refused
   and its detail.

### `bin/start`

`bin/start <branch>` opens work on a new branch while the repo root stays on
`main`. It refuses unless the root is on a clean `main`, `.gitignore` ignores
`.worktrees/`, and neither the branch nor its folder exists. It pulls `main`
when it has an upstream, then creates `.worktrees/<branch>` on a new branch
from `main` and copies `main`'s saved passes into it under the new branch's
name, so the worktree's first `bin/ci` skips everything `main` already
passed. The saved pass holds no folder path or branch name, so the copy
matches. It also gives each app its packages with no install: a link to
the root's `.venv/`, kept out of git through the worktree's exclude file,
and a copy-on-write clone (`cp -c`) of `node_modules/`, a real folder so
Node never reaches into the root's. `bin/dependencies` in the worktree
replaces the `.venv/` link with its own, leaving the root's alone. A script
cannot move the shell that ran it, so its last line names the `cd` into the
worktree that every edit and script after it runs from.

### `bin/merge`

`bin/merge <branch> <msgfile>` lands a branch on `main` as one commit, from
the repo root. It refuses unless the root is clean and the branch has
something new, and switches a root on that branch to `main`; any other
branch is refused. It pulls `main` when it has an upstream, and
refuses a branch that `main` has moved past, so `main` is merged into the
branch and committed there first. It then runs `git merge --squash` and
hands the result to `bin/commit main <msgfile>`, which reviews rules, runs
`bin/ci`, commits and pushes. When that fails, even after the commit, as
when the push is rejected, it resets the root to the commit `main` was on
before the squash, which drops only its own squash.

### `bin/cleanup`

`bin/cleanup` deletes every local branch whose work is already in `main`,
with its worktree under `.worktrees/`. A branch counts as in `main` when
merging it into `main` would change nothing, so a squash-merged branch
counts. It keeps, and says why, a branch whose work is not in `main`, a
worktree with uncommitted changes, a branch checked out anywhere outside
`.worktrees/`, and the branch the repo root is on.

### `bin/complete`

`bin/complete <branch> <msgfile>` runs `bin/merge <branch> <msgfile>` and,
when the branch lands, `bin/cleanup`. Work starts with `bin/start`, is
committed in `.worktrees/<branch>` with `bin/commit --no-push`, and ends
with `bin/complete`.

### Which apps run

1. A flag named after a summary row runs only what it names, whatever is
   dirty: `--<app>` (the folder name, `_` written as `-`), `--root` for the
   root app, `--suite` for the repo-level check. Several combine, and
   `--force` still reruns them past their sentinels. The rules below apply
   when no such flag is given.
2. A dirty path inside an app selects that app. Paths are read as git
   writes them with `-z`, and every git call under the dispatcher runs with
   `core.quotePath` off, so a name with non-ASCII letters is read as is.
3. `CLAUDE.md`, `README.md`, `.claude/`, `tests/`, and `checks/` select
   `bin/_root-tests` on `ci` and `test`, and a `tests/` path also selects the
   root app. On a command with no repo-level check and nothing else
   selected, it prints `bin/<phase>: nothing it checks changed` and exits 0.
4. On `ci` and `test`, a selected app also selects `bin/_root-tests`, and that
   check runs first.
5. A `bin/` path selects every app. Any other path outside every app selects
   the root app when the repo root holds a project file, and every app
   otherwise.
6. On `ci`, `format`, `lint`, `build`, and `test`, a clean tree selects every
   app and `bin/_root-tests`.
7. `dependencies` selects every app.
8. `--force` selects every app, and on `ci` and `test` it also selects
   `bin/_root-tests`.
9. A folder with no project file is not an app. The project file picks the
   language: a `Gemfile` is Rails, `Cargo.toml` Rust, `Package.swift` or an
   Xcode project iOS, `pyproject.toml` Python, `package.json` with
   `tsconfig.json` TypeScript, and `package.json` alone JavaScript. A
   folder with none of those but an executable `test/run` is a shell app.
10. `format` always runs `bin/_root-format` first, whatever is dirty.
11. `changed` runs `bin/_root-changed`, which runs `tests/guards`, first
    whenever anything is dirty.

The selected apps run side by side, at most half the machine's CPU cores at
once, between 1 and 4. `--jobs N` runs at most N at once instead. Ctrl-C
stops every process the dispatcher started.

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
| `bin/open [app]`    | Run the app on 127.0.0.1, open it    |
| `bin/qa [app]`      | Run the app's end-to-end tests       |
| `bin/query "<sql>"` | Run one read-only SQL statement      |
| `bin/start`         | Open a worktree for a new branch     |
| `bin/merge`         | Squash a branch onto `main`          |
| `bin/cleanup`       | Delete branches already in `main`    |
| `bin/complete`      | `bin/merge`, then `bin/cleanup`      |
| `bin/commit`        | Review rules, run `ci`, commit, push |
| `bin/stamp-rules`   | Stamp reviewed rule files            |
| `bin/_dispatch`     | Pick the apps and run the phase      |
| `bin/_ci-timeout`   | Check and record an app's `ci` time  |
| `bin/_root-tests`   | Repo-level check for `ci` and `test` |
| `bin/_root-changed` | Runs `tests/guards` for `changed`    |
| `bin/_root-format`  | Repo-level format for `format`       |
| `bin/scan`          | Search the repo                      |

`bin/_root-tests` runs every executable in `checks/`, on every call even
when the saved pass matches, then `tests/run`; `bin/_root-tests checks/<name>`
runs one check. `bin/_root-changed` runs only `tests/guards`. A check is a
bash script for something the repo must revisit, such as a dated
dependency pin. `bin/_root-format` rewrites every
bash script with `shfmt -i 2 -ci` and fixes every Markdown file with
markdownlint, so a formatting finding from the guards is fixed by
`bin/format`; it fails when markdownlint cannot run, not on the findings
it leaves for the guards. `bin/format --check` passes `--check` on to it,
and it then prints the shfmt diff of every unformatted script, fails, and
rewrites nothing. `bin/ci --clean` passes `--clean` on to
`bin/_root-tests`, which deletes its saved pass. `bin/scan` takes `refs <string>`
(matches, and the commits that added or removed them), `log <git-log-args>`,
`grep <rg-args>` (needs ripgrep) or `files <pathspec>`.

`bin/query "<sql>"` runs one statement through `psql` with no `.psqlrc`,
stopping on the first error, in read-only transactions: it adds
`-c default_transaction_read_only=on` last to `PGOPTIONS`, so it wins over
anything set before it. A statement can still open a read-write
transaction, so it first asks the server what the connected role may do
and refuses a role that is a superuser, may create roles, databases or
schemas, owns a table or sequence, or may insert, update, delete, truncate
or take sequence values anywhere outside the system catalogs; it also
refuses a statement that starts with a backslash, which `psql` would run
as one of its own commands, such as `\!` running a shell. The connection
comes from the standard `PG*` variables, so `PGUSER` names a role that can
only read.

### Language scripts

`bin/_<language>/` holds each language's scripts. The root scripts run them
on each app with `APP_DIR` naming the app's folder; with no `APP_DIR` they run
the root app.

| Script         | What it does                               |
| -------------- | ------------------------------------------ |
| `ci`           | The whole app. Uses the sentinel           |
| `changed`      | Run the steps on what changed. No sentinel |
| `format`       | Format and apply safe fixes                |
| `lint`         | Lint                                       |
| `build`        | Build. Used by `ci`                        |
| `test`         | Test                                       |
| `dependencies` | Update to the newest versions, install     |
| `open`         | Run the app on 127.0.0.1 and open it       |
| `qa`           | Run the end-to-end tests, outside `ci`     |

TypeScript, JavaScript and Rails ship `open`, which `bin/open <app>` runs;
with no app it opens the root app. TypeScript and JavaScript run the `dev`
script with `--host 127.0.0.1 --open`; Rails starts `rails server` on `PORT`
(default 3000) and opens the browser once it answers.

They also ship `qa`, which `bin/qa <app> [args]` runs the same way.
TypeScript and JavaScript install Chromium and run `playwright test` with
the arguments; Rails runs `rails test:system`. A failed test or any warning
in the output fails it. The app brings its own Playwright config and specs.

In `bin/ci`, every step covers the whole app:

- **TypeScript**: Prettier `--check`, a formatter and a linter for every
  file, ESLint with zero warnings and every rule of its recommended set on,
  the package build or `tsc`, then Vitest with 100% functions, lines,
  branches and statements on every source.
- **JavaScript**: `biome format` without writing, a formatter and a linter
  for every file, Biome check, the package build and `node --check`, then the
  package test under c8 with 100% functions, lines, branches and statements
  on every source.
- **Python**: `ruff format --check`, Ruff check, `compileall` and mypy on the
  Python files git lists, then pytest with 100/100 on every source.
- **Rails**: RuboCop's Layout cops and markdownlint, without fixing;
  RuboCop, Brakeman and markdownlint; Zeitwerk; then `db:test:prepare` when
  the app has a database, and Minitest through `rails test`, where warnings
  fail.
- **Rust**: `cargo fmt --check`, then Clippy, `cargo build` and
  `cargo llvm-cov` with a 100% line bar, each over every workspace member.
- **iOS**: each Swift file compared with `swift-format`'s output,
  `swift-format` lint, `swift build` or `xcodebuild`, then `swift test` or
  `xcodebuild` with a 100% line bar.
- **Shell**: `shfmt -d` on every shell script, shellcheck, a check that each
  script with a shebang is executable and parses, then the app's own
  `test/run`.

`bin/format` rewrites instead: Prettier write, Biome write with its safe
fixes, Ruff format and Ruff's safe fixes, RuboCop `-A` and markdownlint
`--fix`, `cargo fmt`, `swift-format` in place, and `shfmt -w`.

### Summary

| Word      | Meaning                                            |
| --------- | -------------------------------------------------- |
| `PASS`    | The work ran and exited 0                          |
| `SKIP`    | The sentinel matched, or that app was not selected |
| `FAIL`    | Exited non-zero                                    |
| Exit code | The result. One `FAIL` fails the command           |

Each row that ran shows how long it took, as in `web : PASS (4m23s)`, and
`elapsed` shows the whole command's time.

## Guards

The app scripts check the code. `tests/guards` checks the standards
themselves. `bin/_root-tests` runs `tests/run`, and `tests/run` runs the
guards, so a broken standard fails the gate like a failing test.

`tests/guards` fails when:

- A text file is over 65,536 bytes. Generated lockfiles are exempt by name;
  any other exemption is an exact path.
- A rule is over 40 lines or 8,000 characters (its stamp excluded), lacks
  one leading H1, has frontmatter or a "Why" or "History" heading, uses
  backward-facing wording, cites a missing rule, or lacks an audit stamp that
  matches its body.
- `CLAUDE.md` is over 400 lines or 12,000 characters, lacks one leading H1,
  uses backward-facing wording, or points at the rules folder or names a
  rule.
- Any file silences a linter, or a lint configuration file holds a setting
  outside its tool's list. Biome, RuboCop, Ruff, Cargo's lint levels,
  swift-format's rules and `.shellcheckrc` each have a list of allowed
  settings, which only turn rules on or up (Biome's `preset` `all` and
  groups at `error`, a RuboCop cop `Enabled: true`); an ESLint config may
  set a rule only to a bare `error`, with no options; markdownlint and
  Brakeman take no config file at all.
- A code file holds a comment, outside strings, regexes and heredocs. Only
  a line-1 shebang, a Ruby magic comment in the leading comment block, a
  `# shellcheck source=` line and line 1 `// swift-tools-version:` of a
  `Package.swift` stay.
- A test is skipped, focused, left as todo or marked as expected to fail,
  in any of the six languages' test runners, or a test file is left out of
  pytest's collection.
- A flag, config or call raises the test time limit for a whole suite, or a
  single test's limit is anything but a plain number.
- A build or coverage output file is tracked or visible to git, or
  `.gitignore` lacks one of `node_modules/`, `dist/`, `build/`,
  `coverage/`, `.venv/`, `target/`, `.build/` and `.flow-states/`.
- SimpleCov starts without `minimum_coverage line: 100, branch: 100` or
  with `add_filter`, `skip` or `filters`, a `.simplecov` file exists, or an
  Xcode test plan or scheme turns coverage off
  or limits it to some targets.
- A bash script has a shellcheck finding or is not formatted by
  `shfmt -i 2 -ci`, or an entry point is not executable or does not start
  with `set -euo pipefail`.
- A Markdown file breaks a markdownlint rule.
- An app's own `bin/` holds `ci`, `changed`, `format`, `lint`, `build`,
  `test`, `dependencies`, `open` or `qa`, or any file sits in `bin/_root/`;
  the root `bin/` runs every app.
- A script in a `bin/_<language>/` folder other than `dependencies` runs a
  package manager's install, lock, resolve, update or add command; a
  `dependencies` script installs without an update; or a language's other
  gate script never runs `packages_check` when its `lib/toolchain.sh`
  defines one.
- `.claude/settings.json` is missing or invalid, does not allow `Bash(bin/*)`
  and `Bash(tests/run)`, allows every command (`Bash` or a pattern that
  starts with a wildcard), does not deny destructive git with and without
  `git -C`, or does not wire both hooks.

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

This repo's `tests/run` runs the guards and the shebang check every time,
then its parts: `tests/core` (setup, hooks, starter, `bin/commit`, the
dispatcher) and `tests/language <language>` for each language. A part runs
only when its inputs changed since its last pass: `bin/`, `starter/`, the
shared helpers in `tests/lib.sh` and `tests/lib/`, `tests/run`, and its own
file and folder. `tests/run --force`, which `bin/ci --force` passes on,
runs every part.

## Permissions and hooks

The starter's `.claude/settings.json` sets what the agent may run:

- **Allows** `Bash(bin/*)` and `Bash(tests/run)`, so the gate runs without
  approval prompts. Both match only the relative form, so scripts are always
  run as `bin/ci`, and one app's scripts as `bin/ci --<app>`. A pattern that
  starts with a wildcard would also match `/usr/bin/git`, so the guards
  reject one, and a bare `Bash` too.
- **Denies** destructive git: `commit` (commits go through `bin/commit`),
  `rebase`, `checkout`, `reset`, `restore`, `stash`, `clean`, and a force-push
  (`--force`, `--force-with-lease`, `-f` or a `+` refspec, wherever it sits
  in the command), with or without `git -C`.
- **Denies editing the gate**: the root `bin/`, `tests/guards`,
  `tests/run`, `.claude/settings.json`, `.claude/hooks/` and `.githooks/`,
  through
  Claude's file tools and the shell commands Claude Code recognizes. A
  person changes the gate; Claude does not. bin-stubs itself keeps its own
  copy of these settings without these denies, so it can work on the gate;
  `tests/run` checks that copy is the starter's less exactly those entries.
- **`require-bin`** (`PreToolUse`) blocks a command that calls the toolchain
  directly (bun, Biome, Ruff, RuboCop, cargo, swift, `rails test` and the
  rest), and a raw `git commit`, anywhere in a compound command, in quotes,
  inside `sh -c`, `$(...)` or backticks, after git options like `-C`, and
  through runners like `npx`, `bundle exec`, `uv run`, `python -m`, `env`,
  `time`, `command`, `exec`, `nohup` and `nice`. The agent is told to use
  the `bin/` script. It blocks a command that sets `CI` or
  `FLOW_CHECKED_APP`, which make the `bin/` scripts skip their toolchain and
  package checks. It also blocks running `bin/stamp-rules` directly, so only
  `bin/commit` stamps a rule, after its review passes.
- **`session-start`** (`SessionStart`) runs `bin/ci` once in a cloud session,
  so the session starts from a known state. A local session is left alone.

The guards fail when the file is missing or invalid, or drops one of the
allows, the git denies or a hook. They leave the gate-edit denies alone, since
bin-stubs runs them on its own copy; its `tests/run` checks those denies.

`.githooks/pre-commit` blocks a person's plain `git commit` too. Just before
it commits, `bin/commit` writes a one-time code under `.git/` and passes it
to `git commit`; the hook deletes the code and refuses any commit that does
not carry it.

## Pinned toolchain

Each app pins its toolchain in a file, and its language's `ci` fails unless
that version is the one running. The check is skipped when `CI` is set.

- **TypeScript** and **JavaScript**: `.nvmrc`. Every `bin/` script, not
  only `bin/ci`, switches to it through nvm when nvm is installed, then
  requires it. `packageManager` in `package.json` pins npm, the one package
  manager the gate runs, and that exact version must be active.
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
- **End-to-end tests**: the kit's `bin/qa` runs them, but the app writes
  them, against a fresh production build served on `127.0.0.1`. Timeouts
  and workers are pinned, nothing retries, and a console error fails the
  test.
- **Test isolation**: every test resets the global state it touches. No test
  reaches the network or production data.
- **Secrets**: never in the repo or the agent's output. A wrapper script
  injects them at run time and never prints them.
