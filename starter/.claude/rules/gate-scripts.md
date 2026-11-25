# Gate Scripts

One copy of each gate script lives in the root `bin/`, and it runs every app
in the repo.

## The Rule

- `bin/_<language>/` holds a language's gate scripts, and the root
  `bin/<script>` runs them on each app with `APP_DIR` naming the app's
  folder; with no `APP_DIR` they run the app at the repo root. Every gate
  script lives under the root `bin/`. `tests/guards` fails a tracked or new
  file named `ci`, `changed`, `format`, `lint`, `build`, `test`,
  `dependencies`, `open` or `qa` in any `bin/` folder below the root, and any
  file under `bin/_root/`, since the root app runs from `bin/_<language>/`
  like every other app. Trigger: a new app, or a file added to an app's
  `bin/`.
- Run on the app at the repo root, a gate script leaves out every file in
  a top-level folder that `is_app_dir` in `bin/lib/apps.sh` names, since
  that folder's app runs on its own; `tests/run` fails a root app's
  `changed`, `format`, `lint` or `build` that lists, rewrites or checks a
  file in such a folder. Trigger: a change to how a gate script lists its
  files.
<!-- audited: 2b53e0967228 -->
