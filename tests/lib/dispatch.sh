#!/usr/bin/env bash

dispatch_repo() {
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/python" "$repo/shell"
  seed_python "$repo/python"
  seed_shell "$repo/shell"
  expect_ok "$repo/bin/dependencies"
  expect_ok "$repo/bin/format"
}

test_dispatch() {
  say "dispatcher"
  local repo sent_python
  dispatch_repo
  expect_ok "$repo/bin/ci"
  local sum
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "PASS" "first python"
  assert_eq "$(row_of shell "$sum")" "PASS" "first shell"
  assert_eq "$(row_of suite "$sum")" "PASS" "first suite"
  grep -qE '^  python +: PASS \(([0-9]+m[0-9]{2}s|[0-9]+s)\)$' "${LAST_LOG}" || die "the summary did not time python"
  grep -qE '^  elapsed  : ([0-9]+m[0-9]{2}s|[0-9]+s)$' "${LAST_LOG}" || die "the summary has no elapsed time"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "second python"
  assert_eq "$(row_of shell "$sum")" "SKIP" "second shell"
  assert_eq "$(row_of suite "$sum")" "SKIP" "second suite"
  printf 'true\n' >>"$repo/shell/add"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "PASS" "edited shell"
  assert_eq "$(row_of python "$sum")" "SKIP" "python untouched"
  sent_python="$(sentinel_file "$repo/python")"
  local python_hash
  python_hash="$(cat "$sent_python")"
  echo "top" >"$repo/TOP.txt"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "foreign file left python"
  assert_eq "$(cat "$sent_python")" "$python_hash" "foreign file changed python hash"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "formatted"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "a commit that changed no file kept python's pass"
  assert_eq "$(row_of shell "$sum")" "SKIP" "a commit that changed no file kept shell's pass"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "clean tree python"
  assert_eq "$(row_of shell "$sum")" "SKIP" "clean tree shell"
  assert_eq "$(row_of suite "$sum")" "SKIP" "clean tree suite"
  [ -f "$repo/.flow-states/main/root-suite-sentinel" ] || die "the suite saved no pass"
  expect_ok "$repo/bin/ci" --clean
  [ ! -f "$repo/.flow-states/main/root-suite-sentinel" ] || die "bin/ci --clean left the suite's saved pass"
  [ ! -f "$repo/python/.flow-states/main/ci-sentinel" ] || die "bin/ci --clean left python's saved pass"
}

test_dispatch_select() {
  say "dispatcher picks apps by what changed"
  local repo sum
  dispatch_repo
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "formatted"
  expect_ok "$repo/bin/ci"
  expect_ok "$repo/bin/ci"
  assert_eq "$(row_of suite "$(summary)")" "SKIP" "second suite"
  echo "corpus" >"$repo/CLAUDE.md"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of suite "$sum")" "PASS" "corpus selects the suite"
  assert_eq "$(row_of python "$sum")" "SKIP" "corpus leaves python"
  assert_eq "$(row_of shell "$sum")" "SKIP" "corpus leaves shell"
  git -C "$repo" add CLAUDE.md
  git -C "$repo" commit -q -m "corpus"
  expect_ok "$repo/bin/ci"
  printf '\n' >>"$repo/bin/_shell/build"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "PASS" "edited shell script"
  assert_eq "$(row_of python "$sum")" "SKIP" "shell script left python"
  mkdir -p "$repo/tests"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'echo "tests/guards ran"' >"$repo/tests/guards"
  chmod +x "$repo/tests/guards"
  git -C "$repo" add tests/guards
  git -C "$repo" commit -q -a -m "shell script"
  expect_ok "$repo/bin/ci"
  printf 'true\n' >>"$repo/shell/add"
  expect_ok "$repo/bin/changed"
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "PASS" "changed shell"
  assert_eq "$(row_of python "$sum")" "SKIP" "changed leaves python"
  assert_eq "$(row_of suite "$sum")" "PASS" "changed runs the guards"
  grep -q "tests/guards ran" "${LAST_LOG}" || die "bin/changed on an app edit did not run tests/guards"
  expect_ok "$repo/bin/test" shell/test/add
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "PASS" "filtered test"
  assert_eq "$(row_of python "$sum")" "SKIP" "filter withheld python"
  expect_ok "$repo/bin/ci" --force --python --suite
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "PASS" "selected python"
  assert_eq "$(row_of suite "$sum")" "PASS" "selected suite"
  assert_eq "$(row_of shell "$sum")" "SKIP" "unselected dirty shell"
  grep -qE '^  shell +: SKIP$' "${LAST_LOG}" || die "the summary timed a target that did not run"
}

test_dispatch_paths() {
  say "the dispatcher sends each changed path to the app that owns it"
  local repo log
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/test" "$repo/a/test" "$repo/tests"
  printf '%s\n' '#!/usr/bin/env bash' >"$repo/test/run"
  printf '%s\n' '#!/usr/bin/env bash' >"$repo/a/test/run"
  chmod +x "$repo/test/run" "$repo/a/test/run"
  cat >"$repo/bin/_shell/build" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$(git rev-parse --show-prefix)" = "" ]; then
  printf 'root\n' >>"$BUILT"
else
  printf '%s\n' "$(git rev-parse --show-prefix)" "$(git ls-files --others --exclude-standard -- .)" >>"$BUILT"
fi
EOF
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "apps"
  log="$WORK/built"
  export BUILT="$log"
  : >"$log"
  : >"$repo/a/naïve"
  expect_ok "$repo/bin/build"
  assert_eq "$(tr '\n' ' ' <"$log")" "a/ naïve " "a non-ASCII name in app a"
  rm "$repo/a/naïve"
  : >"$log"
  : >"$repo/a/two"$'\n'"lines"
  expect_ok "$repo/bin/build"
  assert_eq "$(head -n 1 "$log")" "a/" "a name with a line break in app a"
  rm "$repo/a/two"$'\n'"lines"
  : >"$log"
  printf '%s\n' '#!/usr/bin/env bash' >"$repo/tests/twin"
  expect_ok "$repo/bin/build"
  assert_eq "$(tr '\n' ' ' <"$log")" "root " "a tests/ path with a root app"
  rm "$repo/tests/twin"
  : >"$log"
  printf '# Notes\n' >"$repo/README.md"
  expect_ok "$repo/bin/build"
  grep -qx "bin/build: nothing it checks changed" "${LAST_LOG}" || die "bin/build on a README edit did not say it had nothing to run"
  [ ! -s "$log" ] || die "bin/build ran an app for a README edit"
  unset BUILT
}

test_suite_seal() {
  say "the suite saves the tree it checked, not one its run changed"
  local repo
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/tests"
  cat >"$repo/tests/run" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
chmod +x "$(dirname "$0")/../notes"
EOF
  chmod +x "$repo/tests/run"
  printf 'notes\n' >"$repo/notes"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "suite"
  expect_ok "$repo/bin/ci"
  assert_eq "$(row_of suite "$(summary)")" "PASS" "the suite's first run"
  [ -x "$repo/notes" ] || die "the suite did not change notes during its run"
  expect_ok "$repo/bin/ci"
  assert_eq "$(row_of suite "$(summary)")" "PASS" "a suite whose run changed a file"
  expect_ok "$repo/bin/ci"
  assert_eq "$(row_of suite "$(summary)")" "SKIP" "a suite that changed nothing"
}

test_unborn() {
  say "bin/ci runs on a branch with no commits yet"
  local repo sum
  repo="$WORK/unborn"
  git init -q -b main "$repo"
  printf '.flow-states/\n' >"$repo/.gitignore"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/shell"
  seed_shell "$repo/shell"
  expect_ok "$repo/bin/format"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "PASS" "shell on an unborn branch"
  assert_eq "$(row_of suite "$sum")" "PASS" "the suite on an unborn branch"
  [ -f "$repo/shell/.flow-states/main/ci-sentinel" ] || die "an unborn branch saved its pass under another name"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of shell "$sum")" "SKIP" "shell's second run on an unborn branch"
  assert_eq "$(row_of suite "$sum")" "SKIP" "the suite's second run on an unborn branch"
}

test_steps() {
  say "bin/ci runs an app's four steps at once"
  local repo name
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/shell/test"
  printf '%s\n' '#!/usr/bin/env bash' >"$repo/shell/test/run"
  chmod +x "$repo/shell/test/run"
  for name in format lint build test; do
    cat >"$repo/bin/_shell/$name" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch "$RUNNING/$$"
sleep 1
find "$RUNNING" -type f | wc -l >>"$RUNNING.counts"
rm "$RUNNING/$$"
EOF
  done
  export RUNNING="$WORK/steps-running"
  mkdir -p "$RUNNING"
  expect_ok leaf "$repo/shell" shell ci
  [ "$(sort -n "$RUNNING.counts" | tail -n 1 | tr -d ' ')" -ge 2 ] || die "bin/ci ran its steps one at a time"
  unset RUNNING
}

test_jobs() {
  say "the dispatcher caps how many apps run at once"
  local repo name cap
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  for name in a b c d e; do
    mkdir -p "$repo/$name/test"
    printf '%s\n' '#!/usr/bin/env bash' >"$repo/$name/test/run"
    chmod +x "$repo/$name/test/run"
  done
  cat >"$repo/bin/_shell/build" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch "$RUNNING/$$"
if [ "${APP_DIR##*/}" = a ]; then
  for _ in $(seq 1 100); do
    [ "$(find "$RUNNING" -type f | wc -l)" -lt 2 ] || break
    sleep 0.1
  done
fi
find "$RUNNING" -type f | wc -l >>"$RUNNING.counts"
printf '%s\n' "$*" >>"$RUNNING.args"
sleep 0.3
rm "$RUNNING/$$"
EOF
  export RUNNING="$WORK/running"
  mkdir -p "$RUNNING"
  expect_ok "$repo/bin/build" --jobs 2
  assert_eq "$(sort -n "$RUNNING.counts" | tail -n 1 | tr -d ' ')" 2 "the most apps --jobs 2 ran at once"
  grep -q -- "--jobs" "$RUNNING.args" && die "the dispatcher passed --jobs to an app"
  cap=$(($(getconf _NPROCESSORS_ONLN) / 2))
  [ "$cap" -ge 1 ] || cap=1
  [ "$cap" -le 4 ] || cap=4
  : >"$RUNNING.counts"
  expect_ok "$repo/bin/build"
  [ "$(sort -n "$RUNNING.counts" | tail -n 1 | tr -d ' ')" -le "$cap" ] || die "ran more than $cap apps at once"
  expect_fail "$repo/bin/build" --jobs 0
  grep -q "takes a whole number of at least 1" "${LAST_LOG}" || die "--jobs 0 was accepted"
  unset RUNNING
}

test_interrupt() {
  say "Ctrl-C stops every process the dispatcher started"
  local repo name pid rc=0 tries=0 left leaked tmp="$WORK/interrupt-tmp"
  mkdir -p "$tmp"
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  for name in a b; do
    mkdir -p "$repo/$name/test"
    printf '%s\n' '#!/usr/bin/env bash' >"$repo/$name/test/run"
    chmod +x "$repo/$name/test/run"
  done
  cat >"$repo/bin/_shell/build" <<'EOF'
#!/usr/bin/env bash
sleep 60 &
printf '%s\n' "$$" "$!" "$PPID" >>"$PIDS"
wait
EOF
  export PIDS="$WORK/pids"
  TMPDIR="$tmp" perl -e 'setpgrp(0, 0); $SIG{INT} = "DEFAULT"; exec @ARGV' "$repo/bin/ci" --jobs 2 >/dev/null 2>&1 &
  pid=$!
  until [ -f "$PIDS" ] && [ "$(wc -l <"$PIDS")" -ge 6 ]; do
    kill -0 "$pid" 2>/dev/null || die "bin/ci exited before both apps started"
    sleep 0.1
  done
  kill -INT -- "-$pid"
  wait "$pid" || rc=$?
  assert_eq "$rc" 130 "the dispatcher's exit after Ctrl-C"
  tries=0
  while left="$(ps -o pid= -p "$(paste -sd, - <"$PIDS")")"; do
    tries=$((tries + 1))
    [ "$tries" -le 50 ] || die "Ctrl-C left $(printf '%s' "$left" | wc -l | tr -d ' ') process(es) running"
    sleep 0.1
  done
  unset PIDS
  leaked="$(find "$tmp" -mindepth 1)"
  [ -z "$leaked" ] || die "Ctrl-C left temp files: $(printf '%s' "$leaked" | tr '\n' ' ')"
}

test_ci_time() {
  say "bin/ci records each app's time and fails a slower run"
  local repo host limits file sum row limit took want
  host="$(hostname -s 2>/dev/null || hostname)"
  host="$(printf '%s\n' "$host" | sed -E 's/-[0-9]+$//')"
  limits="$WORK/limits"
  for row in "100 125 1" "100 120 0" "1 5 0"; do
    read -r limit took want <<<"$row"
    printf 'elsewhere 1\n%s %s\n' "$host" "$limit" >"$limits"
    run_log "$HERE/../bin/_ci-timeout" app "$limits" "$took"
    assert_rc "$want" "a ${took}s run against a ${limit}s line"
  done
  grep -qx "$host 5" "$limits" || die "a passing run did not record its time"
  grep -qx "elsewhere 1" "$limits" || die "a passing run changed another machine's line"
  for row in "$host" "$host 1.5"; do
    printf '%s\n' "$row" >"$limits"
    run_log "$HERE/../bin/_ci-timeout" app "$limits" 5
    assert_rc 2 "a line with no whole number of seconds: $row"
    grep -q "is not a whole number of seconds" "${LAST_LOG}" || die "a line with no seconds was not named: $row"
  done

  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/python"
  seed_python "$repo/python"
  expect_ok "$repo/bin/dependencies"
  expect_ok "$repo/bin/format"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "app"
  git -C "$repo" switch -q -c work
  expect_ok "$repo/bin/ci"
  file="$repo/python/.ci-timeout"
  grep -qE "^$host [0-9]+$" "$file" || die "a full pass did not record the app's time"
  expect_ok "$repo/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "a new time file left python unchanged"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$repo/bin/_ci-timeout"
  expect_fail "$repo/bin/ci" --force
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "FAIL" "a slower run"
  [ ! -f "$repo/python/.flow-states/work/ci-sentinel" ] || die "a slower run kept its sentinel"
  [ ! -f "$repo/python/.flow-states/work/ci-test-sentinel" ] || die "a slower run kept its step sentinels"
}

test_root_app() {
  say "root app excludes sibling folders"
  local repo sent hash sum
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  seed_python "$repo"
  mkdir -p "$repo/ios/Sources/App"
  : >"$repo/ios/Package.swift"
  echo "public func other() {}" >"$repo/ios/Sources/App/Other.swift"
  expect_ok "$repo/bin/_python/dependencies"
  expect_ok "$repo/bin/_python/format" --all
  expect_ok "$repo/bin/_python/ci"
  sent="$(sentinel_file "$repo")"
  hash="$(cat "$sent")"
  echo "public func more() {}" >>"$repo/ios/Sources/App/Other.swift"
  expect_ok "$repo/bin/_python/ci"
  grep -q "sentinel written" "${LAST_LOG}" && die "sibling ios edit rewrote the root sentinel"
  assert_eq "$(cat "$sent")" "$hash" "root hash changed"
  printf '\n\ndef test_add_zero() -> None:\n    assert add(0, 0) == 0\n' >>"$repo/tests/test_add.py"
  expect_ok "$repo/bin/_python/ci"
  grep -q "sentinel written" "${LAST_LOG}" || die "the root app kept its pass after its own test changed"
  run_log "$repo/bin/_dispatch" bogus
  assert_rc 2 "an unknown phase"
  grep -qx "bin/_dispatch: unknown phase: bogus" "${LAST_LOG}" || die "the dispatcher ran an unknown phase"
  expect_ok "$repo/bin/ci" --root --force
  sum="$(summary)"
  assert_eq "$(row_of root "$sum")" "PASS" "--root runs the root app"
  assert_eq "$(row_of ios "$sum")" "SKIP" "--root leaves the sibling app"
}

test_root_js() {
  say "a root JavaScript app's build leaves its sibling apps out"
  local repo
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  node --version | sed 's/^v//' >"$repo/.nvmrc"
  printf '{ "name": "root", "private": true, "type": "module" }\n' >"$repo/package.json"
  (cd "$repo" && npm pkg set "packageManager=npm@$(npm --version)")
  mkdir -p "$repo/node_modules" "$repo/src" "$repo/web"
  printf 'export const ok = 1;\n' >"$repo/src/ok.js"
  printf '{ "name": "web", "private": true }\n' >"$repo/web/package.json"
  printf 'export const broken = (;\n' >"$repo/web/broken.js"
  expect_ok "$repo/bin/_javascript/build" --all
  printf 'export const broken = (;\n' >"$repo/src/broken.js"
  expect_fail "$repo/bin/_javascript/build" --all
  grep -q "src/broken.js:1" "${LAST_LOG}" || die "the root app's build skipped its own file"
  grep -q "web/broken.js" "${LAST_LOG}" && die "the root app's build checked a sibling app's file"
  return 0
}

test_root_changed() {
  say "a root Rust or iOS app's changed leaves its sibling apps out"
  local repo lang
  for lang in rust ios; do
    repo="$(new_repo)"
    keep "$repo"
    copy_dir "$HERE/../bin" "$repo/bin"
    mkdir -p "$repo/src" "$repo/web"
    if [ "$lang" = rust ]; then
      printf '[package]\nname = "root"\nversion = "0.1.0"\nedition = "2021"\n' >"$repo/Cargo.toml"
      printf 'pub fn one() -> i32 {\n    1\n}\n' >"$repo/src/lib.rs"
      (cd "$repo" && cargo generate-lockfile --offline -q)
    else
      printf '// swift-tools-version:5.9\nimport PackageDescription\n\nlet package = Package(name: "Root")\n' \
        >"$repo/Package.swift"
    fi
    printf '{ "name": "web", "private": true }\n' >"$repo/web/package.json"
    printf 'export const web = 1;\n' >"$repo/web/web.js"
    run_log "$repo/bin/_$lang/changed" --files
    grep -q "^web/" "${LAST_LOG}" && die "a root $lang app's changed listed a sibling app's file"
    grep -qxE "src/lib.rs|Package.swift" "${LAST_LOG}" || die "a root $lang app's changed left out its own file"
  done
  return 0
}

test_root_shell() {
  say "a root shell app's scripts leave its sibling apps out"
  local repo
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  mkdir -p "$repo/test" "$repo/web"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'echo ok' >"$repo/test/run"
  chmod +x "$repo/test/run"
  printf '{ "name": "web", "private": true }\n' >"$repo/web/package.json"
  printf '%s\n' '#!/usr/bin/env bash' "echo \$1" >"$repo/web/loose.sh"
  run_log "$repo/bin/_shell/changed" --files
  grep -q "web/" "${LAST_LOG}" && die "the root shell app's changed listed a sibling app's file"
  expect_ok "$repo/bin/_shell/lint" --all
  expect_ok "$repo/bin/_shell/format" --check --all
  printf '%s\n' '#!/usr/bin/env bash' "echo \$1" >"$repo/loose.sh"
  expect_fail "$repo/bin/_shell/lint" --all
  grep -q "In loose.sh line 2" "${LAST_LOG}" || die "the root shell app's lint skipped its own file"
  grep -q "web/loose.sh" "${LAST_LOG}" && die "the root shell app's lint checked a sibling app's file"
  return 0
}

test_app_language() {
  say "the dispatcher tells each app's language by its manifest"
  local spec dir file parts files
  # shellcheck source=../../bin/lib/apps.sh
  . "$HERE/../bin/lib/apps.sh"
  for spec in "rails Gemfile" "rust Cargo.toml" "ios Package.swift" "ios App.xcodeproj" "python pyproject.toml" \
    "typescript package.json tsconfig.json" "javascript package.json" "shell test/run"; do
    read -r -a parts <<<"$spec"
    files=("${parts[@]:1}")
    dir="$(mktemp -d "$WORK/app.XXXXXX")"
    for file in "${files[@]}"; do
      case "$file" in
        *.xcodeproj) mkdir -p "$dir/$file" ;;
        test/run)
          mkdir -p "$dir/test"
          printf '#!/usr/bin/env bash\n' >"$dir/test/run"
          chmod +x "$dir/test/run"
          ;;
        *) : >"$dir/$file" ;;
      esac
    done
    is_app_dir "$dir" || die "a folder with ${files[*]} is not an app"
    assert_eq "$(app_language "$dir")" "${parts[0]}" "the language of a folder with ${files[*]}"
  done
  dir="$(mktemp -d "$WORK/app.XXXXXX")"
  is_app_dir "$dir" && die "an empty folder counts as an app"
  app_language "$dir" && die "an empty folder has a language"
  return 0
}
