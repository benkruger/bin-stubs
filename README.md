# bin-stubs

Copy a language `bin/` into an app. Copy the root `bin/` onto a mono-repo. The scripts are the gate.

```
bin/                         copy onto the mono-repo root
ios/bin/                     copy into the iOS app
rails/bin/                   copy into the Rails app
typescript/bin/              copy into the TypeScript app
javascript/bin/              copy into the JavaScript app
python/bin/                  copy into the Python app
rust/bin/                    copy into the Rust app
```

An app that lives at the repo root gets its language `bin/` copied to `bin/_root/` instead of `<app>/bin/`. The folder needs its project file (`Gemfile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `Package.swift`, or an Xcode project) before the dispatcher treats it as an app. This catalog has the scripts only, so `bin/ci` here runs the suite. An unchanged tree returns immediately. `bin/ci --force` re-runs it.

## Configuring a mono-repo

1. Copy `bin/` to the target root.
2. For each app folder, copy the matching language `bin/` into that folder.
3. Run `bin/ci`. The summary lists every app.
4. Run `bin/ci` again. An unchanged app is `SKIP`.

`tests/run` copies those same directories into fixture repos and runs them.

## Dispatcher

`bin/ci`, `format`, `lint`, `build`, `test`, `changed`, and `dependencies` are stubs. Each one hands its phase to `bin/_dispatch`.

The dispatcher discovers folders that have `bin/<phase>`. It does not have a language list.

- A dirty path inside a folder selects that folder.
- `CLAUDE.md`, `README.md`, `.claude/`, `tests/`, and `checks/` select the suite.
- A dirty path in no folder selects the root app when `bin/_root` exists, and every folder otherwise.
- On `ci` and `test`, any selected folder also selects the suite. The suite reads the other trees, so it runs before any format step.
- A clean tree selects every target, so each sentinel can report.
- `changed` with nothing dirty exits green.
- `dependencies` refreshes every folder.
- `--force` selects every target and re-runs `ci`.

The summary lists every discovered target. `PASS` means the leaf ran green. `SKIP` means a `ci` leaf exited 0 without rewriting its sentinel. `skip` means it was not selected. `FAIL` is a non-zero exit. The exit code is the verdict.

## Sentinel

Each folder stores `.flow-states/<branch>/ci-sentinel`. The hash covers that folder's committed tree, both diffs, and untracked regular files. Dependency directories and the sentinel directory are left out. A root app hashes the repo minus the other app folders and the corpus paths.

A matching hash exits green before format, lint, build, and test. A green run stores a new hash taken after those leaves, because format rewrites files. A red run leaves the previous hash in place. `bin/format` and `bin/lint` on their own stay on the dirty set. `bin/ci` passes `--all`, so the run that writes the sentinel has formatted and linted the folder.

These are the misses a later edit has to keep:

- The hash is stored after the run, because format rewrites files.
- The path includes the branch, so two worktrees stay apart.
- A folder hashes its own tree, so a sibling edit leaves it unchanged.
- The modification time only labels `SKIP` versus `PASS`.
- Only regular files are hashed.
- An empty `changed` does not turn into a full run.
