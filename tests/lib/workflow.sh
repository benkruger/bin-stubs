#!/usr/bin/env bash

test_start() {
  say "bin/start opens a worktree with main's saved passes"
  local repo wt sum fetched
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  stub_suite "$repo"
  mkdir -p "$repo/python"
  seed_python "$repo/python"
  expect_ok "$repo/bin/dependencies"
  expect_ok "$repo/bin/format"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "app"
  expect_ok "$repo/bin/ci"
  mkdir -p "$repo/.flow-states/main/commit-review"
  : >"$repo/.flow-states/main/commit-review/round-1-findings.json"

  run_log "$repo/bin/start"
  assert_rc 2 "bin/start with no branch"
  run_log "$repo/bin/start" a/b
  assert_rc 1 "a branch with a slash"
  grep -q "unsafe branch name" "${LAST_LOG}" || die "a slashed branch was not refused"
  run_log "$repo/bin/start" 'bad..name'
  assert_rc 1 "a branch name git refuses"
  grep -q "unsafe branch name: 'bad..name'" "${LAST_LOG}" || die "a branch name git refuses was not refused"
  run_log "$repo/bin/start" feature
  assert_rc 1 "worktrees not ignored"
  grep -q "does not ignore .worktrees/" "${LAST_LOG}" || die "an unignored .worktrees/ was not refused"
  echo ".worktrees/" >>"$repo/.gitignore"
  run_log "$repo/bin/start" feature
  assert_rc 1 "a dirty root"
  grep -q "uncommitted changes" "${LAST_LOG}" || die "a dirty root was not refused"
  git -C "$repo" commit -q -a -m "ignore worktrees"
  git -C "$repo" switch -q -c side
  run_log "$repo/bin/start" feature
  assert_rc 1 "a root off main"
  grep -q "not on main" "${LAST_LOG}" || die "a root off main was not refused"
  git -C "$repo" switch -q main
  run_log "$repo/bin/start" side
  assert_rc 1 "an existing branch"
  grep -q "branch side already exists" "${LAST_LOG}" || die "an existing branch was not refused"
  mkdir -p "$repo/.worktrees/stray"
  run_log "$repo/bin/start" stray
  assert_rc 1 "a worktree folder already there"
  grep -q "\.worktrees/stray already exists" "${LAST_LOG}" || die "an existing worktree folder was not refused"
  rmdir "$repo/.worktrees/stray"
  expect_ok "$repo/bin/ci"
  mkdir -p "$repo/web/node_modules/pkg"
  echo "module.exports = 1;" >"$repo/web/node_modules/pkg/index.js"
  mkdir -p "$repo/ios/.build/checkouts/dep" "$repo/ios/.build/repositories/dep" "$repo/ios/.build/xcode-packages/checkouts" \
    "$repo/ios/.build/debug"
  printf '{ "object": { "dependencies": [] } }\n' >"$repo/ios/.build/workspace-state.json"
  : >"$repo/ios/.build/checkouts/dep/Package.swift"
  : >"$repo/ios/.build/repositories/dep/HEAD"
  : >"$repo/ios/.build/xcode-packages/workspace-state.json"
  : >"$repo/ios/.build/debug/App"

  expect_ok "$repo/bin/start" feature
  tail -n 1 "${LAST_LOG}" | grep -qxF "bin/start: next, run 'cd .worktrees/feature' on its own and make every edit and run every script there" ||
    die "bin/start did not end by naming the cd into its worktree"
  wt="$repo/.worktrees/feature"
  [ -L "$wt/python/.venv" ] || die "bin/start did not link python's .venv"
  assert_eq "$(cd "$wt/python/.venv" && pwd -P)" "$(cd "$repo/python/.venv" && pwd -P)" "the linked .venv"
  [ -d "$wt/web/node_modules" ] && [ ! -L "$wt/web/node_modules" ] || die "bin/start did not copy node_modules as a folder"
  assert_eq "$(cat "$wt/web/node_modules/pkg/index.js")" "module.exports = 1;" "the cloned node_modules"
  assert_eq "$(cat "$wt/ios/.build/workspace-state.json")" '{ "object": { "dependencies": [] } }' "the cloned Swift package state"
  for fetched in checkouts/dep/Package.swift repositories/dep/HEAD xcode-packages/workspace-state.json; do
    [ -f "$wt/ios/.build/$fetched" ] || die "bin/start did not clone the Swift packages' $fetched"
  done
  [ ! -e "$wt/ios/.build/debug" ] || die "bin/start cloned main's Swift build products"
  [ -z "$(git -C "$wt" status --porcelain)" ] || die "the worktree's packages show up in git"
  assert_eq "$(git -C "$wt" branch --show-current)" "feature" "the worktree's branch"
  assert_eq "$(git -C "$wt" rev-parse HEAD)" "$(git -C "$repo" rev-parse main)" "the worktree's base"
  assert_eq "$(cat "$wt/python/.flow-states/feature/ci-sentinel")" "$(cat "$repo/python/.flow-states/main/ci-sentinel")" "the copied pass"
  [ ! -e "$wt/.flow-states/feature/commit-review" ] || die "bin/start copied main's commit review logs"
  expect_ok "$wt/bin/ci"
  sum="$(summary)"
  assert_eq "$(row_of python "$sum")" "SKIP" "the worktree's first python run"
  assert_eq "$(row_of suite "$sum")" "SKIP" "the worktree's first suite run"
  expect_ok "$wt/bin/test" --python
  assert_eq "$(row_of python "$(summary)")" "PASS" "the worktree's python tests on main's packages"
  expect_ok "$wt/bin/dependencies" --python
  [ -d "$wt/python/.venv" ] && [ ! -L "$wt/python/.venv" ] || die "bin/dependencies kept the link to main's .venv"
  [ -d "$repo/python/.venv" ] && [ ! -L "$repo/python/.venv" ] || die "the worktree's bin/dependencies changed main's .venv"
}

minted() {
  local file
  file="$(mktemp /tmp/flow-commit-msg.XXXXXX)"
  litter "$file"
  printf '%s\n' "$1" >"$file"
  printf '%s\n' "$file"
}

test_merge() {
  say "bin/merge squashes a branch onto main through bin/commit"
  local repo origin wt base
  repo="$(new_repo)"
  keep "$repo"
  origin="$WORK/merge-origin.git"
  copy_dir "$HERE/../starter" "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  stand_in_ci "$repo"
  echo ".worktrees/" >>"$repo/.gitignore"
  printf '# Notes\n' >"$repo/notes.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m starter
  git init -q --bare "$origin"
  git -C "$repo" remote add origin "$origin"
  git -C "$repo" push -q -u origin main

  run_log "$repo/bin/merge"
  assert_rc 2 "bin/merge with no arguments"
  run_log "$repo/bin/merge" a/b "$(minted 'Land nothing')"
  assert_rc 1 "a branch with a slash"
  grep -q "unsafe branch name: 'a/b'" "${LAST_LOG}" || die "bin/merge took an unsafe branch name"
  run_log "$repo/bin/merge" nosuch "$(minted 'Land nothing')"
  assert_rc 1 "a missing branch"
  grep -q "no branch nosuch" "${LAST_LOG}" || die "a missing branch was not refused"
  expect_ok "$repo/bin/start" feature
  assert_eq "$(git -C "$repo" config --get core.hooksPath)" ".githooks" "the hooks path bin/start set"
  wt="$repo/.worktrees/feature"
  run_log "$repo/bin/merge" feature "$(minted 'Land nothing')"
  assert_rc 1 "a branch with nothing new"
  grep -q "nothing to merge" "${LAST_LOG}" || die "an empty branch was not refused"

  printf '\nFeature.\n' >>"$wt/notes.md"
  expect_ok "$wt/bin/commit" --no-push feature "$(minted 'Add the feature')"
  printf '# Other\n' >"$repo/other.md"
  expect_ok "$repo/bin/commit" main "$(minted 'Move main')"
  run_log "$repo/bin/merge" feature "$(minted 'Land the feature')"
  assert_rc 1 "main moved on"
  grep -q "main has moved on since feature started" "${LAST_LOG}" || die "a stale branch was not refused"
  git -C "$wt" merge -q --no-edit main

  mkdir -p "$wt/.flow-states/feature/commit-review" "$wt/app/.flow-states/feature" "$repo/.flow-states/main/commit-review"
  printf 'suite pass\n' >"$wt/.flow-states/feature/root-suite-sentinel"
  printf 'app pass\n' >"$wt/app/.flow-states/feature/ci-sentinel"
  : >"$wt/.flow-states/feature/commit-review/branch-round.json"
  : >"$repo/.flow-states/main/commit-review/main-round.json"
  base="$(git -C "$repo" rev-parse HEAD)"
  expect_ok "$repo/bin/merge" feature "$(minted 'Land the feature')"
  assert_eq "$(cat "$repo/.flow-states/main/root-suite-sentinel")" "suite pass" "the branch's suite pass on main"
  assert_eq "$(cat "$repo/app/.flow-states/main/ci-sentinel")" "app pass" "the branch's app pass on main"
  [ -e "$repo/.flow-states/main/commit-review/main-round.json" ] || die "bin/merge dropped main's commit review logs"
  [ ! -e "$repo/.flow-states/main/commit-review/branch-round.json" ] || die "bin/merge copied the branch's commit review logs"
  assert_eq "$(git -C "$repo" log -1 --format=%s)" "Land the feature" "the squash's message"
  assert_eq "$(git -C "$repo" rev-parse HEAD^)" "$base" "one commit on main"
  assert_eq "$(git -C "$repo" rev-parse 'HEAD^{tree}')" "$(git -C "$repo" rev-parse 'feature^{tree}')" "the squash's tree"
  assert_eq "$(git -C "$origin" rev-parse main)" "$(git -C "$repo" rev-parse HEAD)" "the push of main"
  [ -z "$(git -C "$repo" status --porcelain)" ] || die "a landed merge left the root dirty"

  git -C "$wt" merge -q --no-edit main
  mkdir -p "$wt/checks"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$wt/checks/red"
  chmod +x "$wt/checks/red"
  git -C "$wt" add -A
  git -C "$wt" -c core.hooksPath=/dev/null commit -q -m "red"
  base="$(git -C "$repo" rev-parse HEAD)"
  printf 'red pass\n' >"$wt/.flow-states/feature/root-suite-sentinel"
  printf 'red app pass\n' >"$wt/app/.flow-states/feature/ci-sentinel"
  rm -rf "$repo/app/.flow-states/main"
  run_log "$repo/bin/merge" feature "$(minted 'Land a red feature')"
  assert_rc 1 "a red squash"
  grep -q "did not land; main is back where it was" "${LAST_LOG}" || die "a red squash did not say it was undone"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$base" "a red squash committed"
  [ -z "$(git -C "$repo" status --porcelain)" ] || die "a red squash left the root dirty"
  assert_eq "$(cat "$repo/.flow-states/main/root-suite-sentinel")" "suite pass" "main's suite pass after a red squash"
  [ ! -e "$repo/app/.flow-states/main/ci-sentinel" ] || die "a red squash left the branch's app pass on main"
  [ -e "$repo/.flow-states/main/commit-review/main-round.json" ] || die "a red squash dropped main's commit review logs"

  git -C "$wt" rm -q checks/red
  printf '\nPushed later.\n' >>"$wt/notes.md"
  git -C "$wt" add -A
  git -C "$wt" -c core.hooksPath=/dev/null commit -q -m "green"
  printf '%s\n' '#!/bin/sh' 'exit 1' >"$origin/hooks/pre-receive"
  chmod +x "$origin/hooks/pre-receive"
  run_log "$repo/bin/merge" feature "$(minted 'Land a feature the remote refuses')"
  assert_rc 1 "a squash whose push failed"
  grep -q "did not land; main is back where it was" "${LAST_LOG}" || die "a refused push did not say it was undone"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$base" "a refused push left its squash on main"
  [ -z "$(git -C "$repo" status --porcelain)" ] || die "a refused push left the root dirty"
  assert_eq "$(cat "$repo/.flow-states/main/root-suite-sentinel")" "suite pass" "main's suite pass after a refused push"
  rm "$origin/hooks/pre-receive"

  git -C "$repo" switch -q -c rootwork
  printf '\nRoot work.\n' >>"$repo/notes.md"
  expect_ok "$repo/bin/commit" --no-push rootwork "$(minted 'Add root work')"
  echo "dirty" >"$repo/scratch.txt"
  run_log "$repo/bin/merge" rootwork "$(minted 'Land root work')"
  assert_rc 1 "a dirty root on the branch"
  grep -q "the repo root has uncommitted changes" "${LAST_LOG}" || die "a dirty root on the branch was not refused"
  assert_eq "$(git -C "$repo" branch --show-current)" rootwork "the root after a refused merge"
  rm "$repo/scratch.txt"
  git -C "$repo" branch -q other
  git -C "$repo" switch -q other
  run_log "$repo/bin/merge" rootwork "$(minted 'Land root work')"
  assert_rc 1 "a root on another branch"
  grep -q "the repo root is not on main" "${LAST_LOG}" || die "a root on another branch was not refused"
  git -C "$repo" switch -q rootwork
  mkdir -p "$repo/.flow-states/rootwork"
  printf 'root pass\n' >"$repo/.flow-states/rootwork/root-suite-sentinel"
  expect_ok "$repo/bin/merge" rootwork "$(minted 'Land root work')"
  assert_eq "$(cat "$repo/.flow-states/main/root-suite-sentinel")" "root pass" "the root branch's pass on main"
  assert_eq "$(git -C "$repo" branch --show-current)" main "the root after landing its own branch"
  assert_eq "$(git -C "$repo" log -1 --format=%s)" "Land root work" "the squash from the root's branch"
  assert_eq "$(git -C "$repo" rev-parse HEAD^)" "$base" "one commit on main from the root's branch"

  git -C "$repo" remote remove origin
  git -C "$repo" switch -q -c localwork
  printf '\nLocal work.\n' >>"$repo/notes.md"
  expect_ok "$repo/bin/commit" --no-push localwork "$(minted 'Add local work')"
  base="$(git -C "$repo" rev-parse main)"
  expect_ok "$repo/bin/merge" localwork "$(minted 'Land local work')"
  assert_eq "$(git -C "$repo" rev-parse HEAD^)" "$base" "a squash in a repo with no remote"
}

test_cleanup() {
  say "bin/cleanup removes branches whose work is in main"
  local repo branch wts
  repo="$(new_repo)"
  keep "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  echo ".worktrees/" >>"$repo/.gitignore"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "bin"
  run_log "$repo/bin/cleanup" extra
  assert_rc 2 "bin/cleanup with an argument"
  wts="$repo/.worktrees"
  for branch in merged squashed open dirty; do
    expect_ok "$repo/bin/start" "$branch"
    printf '%s\n' "$branch" >"$wts/$branch/$branch.txt"
    git -C "$wts/$branch" add -A
    git -C "$wts/$branch" commit -q -m "$branch"
  done
  expect_ok "$repo/bin/start" fresh
  git -C "$repo" branch -q --no-track plain main
  git -C "$repo" worktree add -q "$WORK/elsewhere" -b elsewhere
  git -C "$repo" merge -q --ff-only merged
  for branch in squashed dirty; do
    git -C "$repo" merge -q --squash "$branch" >/dev/null 2>&1
    git -C "$repo" commit -q -m "squash $branch"
  done
  echo "edit" >>"$wts/dirty/dirty.txt"
  git -C "$repo" switch -q -c here

  expect_ok "$repo/bin/cleanup"
  grep -qx "bin/cleanup: kept here: checked out at the repo root" "${LAST_LOG}" ||
    die "bin/cleanup did not keep the branch the root has checked out"
  for branch in merged squashed plain; do
    grep -qx "bin/cleanup: removed $branch" "${LAST_LOG}" || die "bin/cleanup kept $branch"
    git -C "$repo" rev-parse -q --verify "refs/heads/$branch" >/dev/null && die "bin/cleanup left the $branch branch"
  done
  [ ! -e "$wts/merged" ] && [ ! -e "$wts/squashed" ] || die "bin/cleanup left a merged worktree"
  grep -qx "bin/cleanup: kept open: its work is not in main" "${LAST_LOG}" || die "bin/cleanup did not keep unmerged work"
  grep -q "^bin/cleanup: kept dirty: uncommitted changes in " "${LAST_LOG}" || die "bin/cleanup did not keep a dirty worktree"
  grep -q "^bin/cleanup: kept elsewhere: checked out at " "${LAST_LOG}" || die "bin/cleanup did not keep a branch checked out elsewhere"
  [ -d "$wts/open" ] && [ -d "$wts/dirty" ] || die "bin/cleanup removed a kept worktree"
  grep -qx "bin/cleanup: kept fresh: started but nothing committed" "${LAST_LOG}" ||
    die "bin/cleanup did not keep a worktree bin/start just opened"
  [ -d "$wts/fresh" ] || die "bin/cleanup removed a worktree bin/start just opened"
}

test_complete() {
  say "bin/complete lands a branch and deletes it"
  local repo origin wt base
  repo="$(new_repo)"
  keep "$repo"
  origin="$WORK/complete-origin.git"
  copy_dir "$HERE/../starter" "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  echo ".worktrees/" >>"$repo/.gitignore"
  printf '# Notes\n' >"$repo/notes.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m starter
  git init -q --bare "$origin"
  git -C "$repo" remote add origin "$origin"
  git -C "$repo" push -q -u origin main
  git -C "$repo" config core.hooksPath .githooks

  run_log "$repo/bin/complete" feature
  assert_rc 2 "bin/complete with one argument"
  expect_ok "$repo/bin/start" feature
  wt="$repo/.worktrees/feature"
  run_log "$repo/bin/complete" feature "$(minted 'Land nothing')"
  assert_rc 1 "a branch with nothing new"
  [ -d "$wt" ] || die "bin/complete cleaned up a branch that did not land"
  printf '\nFeature.\n' >>"$wt/notes.md"
  expect_ok "$wt/bin/commit" --no-push feature "$(minted 'Add the feature')"
  base="$(git -C "$repo" rev-parse HEAD)"
  expect_ok "$wt/bin/complete" feature "$(minted 'Land the feature')"
  assert_eq "$(git -C "$repo" rev-parse HEAD^)" "$base" "one commit on main"
  assert_eq "$(git -C "$origin" rev-parse main)" "$(git -C "$repo" rev-parse HEAD)" "the push of main"
  grep -qx "bin/cleanup: removed feature" "${LAST_LOG}" || die "bin/complete did not clean up"
  [ ! -e "$wt" ] || die "bin/complete left the worktree"
  git -C "$repo" rev-parse -q --verify refs/heads/feature >/dev/null && die "bin/complete left the branch"
  return 0
}
