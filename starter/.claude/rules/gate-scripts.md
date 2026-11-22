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
<!-- audited: 451363fba03d -->
