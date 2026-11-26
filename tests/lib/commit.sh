#!/usr/bin/env bash

fake_claude() {
  mkdir -p "$1"
  cat >"$1/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prompt="$(cat)"
case "$prompt" in
  *"You are the rule-fixer."*)
    echo "fix $*" >>"$FAKE_CLAUDE_LOG"
    files='[]'
    while IFS= read -r f; do
      case "${FAKE_FIX:-}" in
        good) text="$(perl -pe 's/BAD/GOOD/' "$f")" ;;
        arrow) text="$(perl -pe 's/BAD rule\./GOOD rule →./' "$f")" ;;
        grow) text="$(cat "$f" && for _ in $(seq 1 50); do echo "- more"; done)" ;;
        outside)
          f=notes.md
          text="replaced"
          ;;
        newfile)
          f=.claude/rules/split.md
          text="# Split"
          ;;
        *) continue ;;
      esac
      files="$(jq -c --arg p "$f" --arg c "$text"$'\n' '. + [{path: $p, content: $c}]' <<<"$files")"
    done < <(awk '/^## Files you may change$/ { on = 1; next } /^## / { on = 0 }
      on && /^- / { print substr($0, 3) }' <<<"$prompt")
    printf '{"type":"result","is_error":false,"structured_output":{"files":%s}}\n' "$files"
    ;;
  *)
    if grep -q '^audit' "$FAKE_CLAUDE_LOG"; then
      echo "verify $*" >>"$FAKE_CLAUDE_LOG"
      printf '%s\n' "$prompt" >"$FAKE_CLAUDE_LOG.recheck"
      if [ -n "${FAKE_VERIFY_SEQ:-}" ]; then
        word="$(printf '%s\n' ${FAKE_VERIFY_SEQ} | sed -n "$(grep -c '^verify' "$FAKE_CLAUDE_LOG")p")"
        if [ -n "$word" ]; then
          printf '{"type":"result","is_error":false,"structured_output":{"findings":[{"file":".claude/rules/probe.md","requirement":"r","offending":"%s","fix":"f"}]}}\n' "$word"
        else
          echo '{"type":"result","is_error":false,"structured_output":{"findings":[]}}'
        fi
      elif [ "${FAKE_VERIFY:-}" = none ]; then
        echo '{"type":"result","is_error":false}'
      else
        printf '{"type":"result","is_error":false,"structured_output":{"findings":%s}}\n' "${FAKE_VERIFY:-[]}"
      fi
      exit 0
    fi
    echo "audit $*" >>"$FAKE_CLAUDE_LOG"
    printf '%s\n' "$prompt" >"$FAKE_CLAUDE_LOG.prompt"
    if [ "${FAKE_AUDIT:-}" = none ]; then
      echo '{"type":"result","is_error":false}'
    else
      printf '{"type":"result","is_error":false,"structured_output":{"findings":%s}}\n' "${FAKE_AUDIT:-[]}"
    fi
    ;;
esac
EOF
  chmod +x "$1/claude"
}

commit_json() { jq -r "$1" "${LAST_LOG}"; }

stand_in_ci() {
  cat >"$1/bin/ci" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
for check in checks/*; do
  [ ! -x "$check" ] || "$check"
done
EOF
}

real_ci() { cp "$HERE/../bin/ci" "$repo/bin/ci"; }

commit_base() {
  local base="$WORK/commit-base" repo
  repo="$(new_repo)"
  copy_dir "$HERE/../starter" "$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  stand_in_ci "$repo"
  printf '# Notes\n' >"$repo/notes.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m starter
  mkdir -p "$base"
  mv "$repo" "$base/repo"
  git init -q --bare "$base/origin.git"
  git -C "$base/repo" push -q "$base/origin.git" main
}

commit_case() {
  local dir
  dir="$(mktemp -d "$WORK/commit-case.XXXXXX")"
  cp -cR "$WORK/commit-base/." "$dir" 2>/dev/null || cp -R "$WORK/commit-base/." "$dir"
  repo="$dir/repo"
  origin="$dir/origin.git"
  rule="$repo/.claude/rules/probe.md"
  keep "$repo"
  git -C "$repo" remote add origin "$origin"
  git -C "$repo" config core.hooksPath .githooks
}

commit() {
  local vars=()
  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    vars+=("$1")
    shift
  done
  [ "$#" -eq 0 ] || shift
  : >"$CLAUDE_LOG"
  rm -f "$CLAUDE_LOG.prompt" "$CLAUDE_LOG.recheck"
  run_log env PATH="$FAKE_CLAUDE:$PATH" FAKE_CLAUDE_LOG="$CLAUDE_LOG" \
    ${vars[@]+"${vars[@]}"} "$repo/bin/commit" "$@"
}

sessions() { cut -d' ' -f1 "$CLAUDE_LOG" | tr '\n' ' '; }

commit_setup() {
  FAKE_CLAUDE="$WORK/fake-claude"
  CLAUDE_LOG="$WORK/claude.log"
  fake_claude "$FAKE_CLAUDE"
  commit_base
  msg="$(mktemp /tmp/flow-commit-msg.XXXXXX)"
  litter "$msg"
  printf '  Add notes  \n\n' >"$msg"
  finding='[{"file":".claude/rules/probe.md","requirement":"r","offending":"BAD","fix":"say GOOD"}]'
}

test_commit() {
  say "commit"
  local repo origin rule msg empty finding sha before
  commit_setup
  empty="$(mktemp /tmp/flow-commit-msg.XXXXXX)"
  litter "$empty"
  printf '  \n' >"$empty"

  commit_case
  commit --
  assert_rc 1 "bin/commit with no arguments"
  assert_eq "$(commit_json .step)" "usage" "bin/commit with no arguments"
  assert_eq "$(commit_json .detail)" "usage: bin/commit [--no-push] <branch> <msgfile>" "the usage refusal's detail"
  commit -- a/b "$msg"
  assert_rc 1 "a branch with a slash"
  assert_eq "$(commit_json .step)" "branch" "a branch with a slash"
  assert_eq "$(commit_json .detail)" "unsafe branch: a/b" "the unsafe branch refusal's detail"
  printf 'x\n' >"$WORK/invented-msg"
  commit -- main "$WORK/invented-msg"
  assert_rc 1 "an invented message file"
  assert_eq "$(commit_json .step)" "message_path" "an invented message file"
  commit -- main /tmp/flow-commit-msg.XXXXXX
  assert_eq "$(commit_json .step)" "message_path" "the mktemp template"
  commit -- main "$empty"
  assert_eq "$(commit_json .step)" "message_missing" "an empty message"

  commit_case
  commit -- main "$msg"
  assert_rc 1 "a clean tree"
  assert_eq "$(commit_json .step)" "empty" "a clean tree"

  commit_case
  before="$(git -C "$repo" rev-parse HEAD)"
  printf '\nTypo.\n' >>"$repo/notes.md"
  commit -- typo "$msg"
  assert_rc 1 "a branch the checkout is not on"
  assert_eq "$(commit_json .step)" "branch" "a branch the checkout is not on"
  commit_json .detail | grep -q "is on main, not typo" || die "the branch refusal did not name both branches"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "a mismatched branch committed"

  commit_case
  before="$(git -C "$repo" rev-parse HEAD)"
  mkdir -p "$repo/checks"
  printf '%s\n' '#!/usr/bin/env bash' 'echo "the red check said no"' 'exit 1' >"$repo/checks/red"
  chmod +x "$repo/checks/red"
  commit -- main "$msg"
  assert_eq "$(commit_json .step)" "ci" "a red bin/ci"
  commit_json .detail | grep -q "the red check said no" || die "the red bin/ci output is missing from the detail"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "a red bin/ci committed"

  commit_case
  printf '\nMore.\n' >>"$repo/notes.md"
  commit -- main "$msg"
  assert_rc 0 "a green commit"
  sha="$(commit_json .sha)"
  assert_eq "$sha" "$(git -C "$repo" rev-parse HEAD)" "the printed sha"
  assert_eq "$(git -C "$origin" rev-parse main)" "$sha" "the push to origin"
  assert_eq "$(git -C "$repo" log -1 --format=%B)" "Add notes" "the trimmed message"
  [ ! -s "$CLAUDE_LOG" ] || die "claude ran with no rule edited"

  commit_case
  before="$(git -C "$origin" rev-parse main)"
  printf '\nMore.\n' >>"$repo/notes.md"
  commit -- --no-push main "$msg"
  assert_rc 0 "a commit without a push"
  assert_eq "$(commit_json .sha)" "$(git -C "$repo" rev-parse HEAD)" "the unpushed commit"
  assert_eq "$(git -C "$origin" rev-parse main)" "$before" "--no-push pushed"

  commit_case
  git -C "$repo" config --unset core.hooksPath
  printf '\nArmed.\n' >>"$repo/notes.md"
  commit -- --no-push main "$msg"
  assert_rc 0 "a commit in a repo whose hooks were never switched on"
  assert_eq "$(git -C "$repo" config --get core.hooksPath)" ".githooks" "the hooks path bin/commit set"
  printf '\nRaw.\n' >>"$repo/notes.md"
  git -C "$repo" add -A
  run_log git -C "$repo" commit -q -m raw
  assert_rc 1 "a raw commit after bin/commit switched the hooks on"

  commit_case
  before="$(git -C "$repo" rev-parse HEAD)"
  printf '\nRaw.\n' >>"$repo/notes.md"
  git -C "$repo" add -A
  run_log git -C "$repo" commit -q -m raw
  assert_rc 1 "a commit bin/commit did not start"
  grep -q "pre-commit: commit with bin/commit" "${LAST_LOG}" || die "the hook did not name bin/commit"
  marker="$(git -C "$repo" rev-parse --path-format=absolute --git-path flow-commit-marker)"
  printf 'issued\n' >"$marker"
  run_log env FLOW_COMMIT_NONCE=guessed git -C "$repo" commit -q -m raw
  assert_rc 1 "a commit with the wrong code"
  [ ! -f "$marker" ] || die "a refused commit left its code for another try"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "a refused commit landed"
}

test_commit_review() {
  say "commit reviews the rules a change adds or edits"
  local repo origin rule msg finding
  commit_setup

  commit_case
  real_ci
  printf '# Probe\n\nA probe rule.\n' >"$rule"
  commit -- main "$msg"
  assert_rc 0 "a clean rule review"
  tail -n 1 "$rule" | grep -qE '^<!-- audited: [0-9a-f]{12} -->$' || die "a clean review did not stamp the rule"
  assert_eq "$(sessions)" "audit " "a clean review's sessions"
  grep -q -- "--json-schema" "$CLAUDE_LOG" || die "the auditor ran without a findings schema"
  if grep -q "## Changes since the last review" "$CLAUDE_LOG.prompt"; then
    die "a new rule was judged on changed lines only"
  fi

  commit_case
  printf '# Probe\n\nA probe rule.\n' >"$rule"
  "$repo/bin/stamp-rules" "$rule"
  commit -- main "$msg"
  assert_rc 0 "a rule already stamped for its text"
  [ ! -s "$CLAUDE_LOG" ] || die "a rule whose stamp matches its text was reviewed again"

  commit_case
  perl -0pi -e 's/\n<!-- audited/\n- A probe line.\n<!-- audited/' "$repo/.claude/rules/guard-tests.md"
  commit -- main "$msg"
  assert_rc 0 "an edit to a reviewed rule"
  grep -q "## Changes since the last review" "$CLAUDE_LOG.prompt" ||
    die "a reviewed rule was not judged on its changed lines"
  grep -qx "### .claude/rules/guard-tests.md" "$CLAUDE_LOG.prompt" ||
    die "a reviewed rule's review left out its file"
  grep -qx "+- A probe line." "$CLAUDE_LOG.prompt" ||
    die "the review did not see the changed line"
  grep -q "never ask for a new file" "$CLAUDE_LOG.prompt" || die "the review may ask for a new file"

  commit_case
  mkdir -p "$repo/app/.claude/rules"
  printf '# Probe\n\nA probe rule.\n' >"$repo/app/.claude/rules/probe.md"
  commit -- main "$msg"
  assert_rc 0 "a nested rule review"
  grep -qx "### .claude/rules/guard-tests.md" "$CLAUDE_LOG.prompt" ||
    die "the review of a nested rule left out the root rules"

  commit_case
  printf '# Spaced\n\nA rule whose name has a space.\n' >"$repo/.claude/rules/my rule.md"
  commit -- main "$msg"
  assert_rc 0 "a rule whose name has a space"
  tail -n 1 "$repo/.claude/rules/my rule.md" | grep -qE '^<!-- audited: [0-9a-f]{12} -->$' ||
    die "a rule whose name has a space was not reviewed and stamped"
}

test_commit_fix() {
  say "commit keeps only the fixer's edits to the flagged rules"
  local repo origin rule msg finding
  commit_setup

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good -- main "$msg"
  assert_rc 0 "a fixed finding"
  grep -q "A GOOD rule." "$rule" || die "the fixer's text was not written"
  tail -n 1 "$rule" | grep -qE '^<!-- audited: ' || die "a fixed rule was not stamped"
  assert_eq "$(sessions)" "audit fix verify " "a fixed finding's sessions"
  grep -qx "+A GOOD rule." "$CLAUDE_LOG.recheck" ||
    die "the review after a fix did not see the lines the fix changed"
  grep -qF -- "- .claude/rules/probe.md: r — BAD → say GOOD" "$CLAUDE_LOG.recheck" ||
    die "the review after a fix did not check the prior findings"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=outside -- main "$msg"
  assert_rc 0 "a fix outside the rules"
  grep -qx "# Notes" "$repo/notes.md" || die "the fixer wrote outside the rules"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=newfile -- main "$msg"
  assert_rc 0 "a fix that adds a rule file"
  [ ! -e "$repo/.claude/rules/split.md" ] || die "the fixer created a rule file nobody flagged"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=grow -- main "$msg"
  assert_rc 0 "an over-bound fix"
  [ "$(grep -c -- "- more" "$rule" || true)" -eq 0 ] || die "an over-bound fix was kept"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  sed 's/^MAX_RULE_CHARS=8000$/MAX_RULE_CHARS=21/' "$repo/tests/guards" >"$WORK/guards.capped"
  cat "$WORK/guards.capped" >"$repo/tests/guards"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good -- main "$msg"
  assert_rc 0 "a fix over the cap tests/guards sets"
  grep -q "A GOOD rule." "$rule" &&
    die "bin/commit kept a fix one character over the cap tests/guards sets, its final newline counted"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  sed 's/^MAX_RULE_CHARS=8000$/MAX_RULE_CHARS=24/' "$repo/tests/guards" >"$WORK/guards.capped"
  cat "$WORK/guards.capped" >"$repo/tests/guards"
  commit FAKE_AUDIT="$finding" FAKE_FIX=arrow -- main "$msg"
  grep -q "A GOOD rule →." "$rule" || die "bin/commit dropped a fix within the cap, counting bytes not characters"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  grep -v '^MAX_RULE_CHARS=' "$repo/tests/guards" >"$WORK/guards.uncapped"
  cat "$WORK/guards.uncapped" >"$repo/tests/guards"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good -- main "$msg"
  assert_rc 1 "a rule review with no cap in tests/guards"
  assert_eq "$(commit_json .detail)" "rule audit: tests/guards sets no MAX_RULE_LINES or MAX_RULE_CHARS" \
    "a rule review with no cap in tests/guards"
}

test_commit_rounds() {
  say "commit runs fix rounds until the review is clean or stuck"
  local repo origin rule msg finding before
  commit_setup

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good FAKE_VERIFY_SEQ="one two three four" -- main "$msg"
  assert_rc 0 "a new finding each round until clean"
  assert_eq "$(sessions)" "audit fix verify fix verify fix verify fix verify fix verify " \
    "rounds that keep making progress"

  commit_case
  before="$(git -C "$repo" rev-parse HEAD)"
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_VERIFY="$finding" -- main "$msg"
  assert_rc 1 "an unresolved finding"
  assert_eq "$(commit_json .step)" "ci" "an unresolved finding"
  assert_eq "$(commit_json .detail | head -n 2)" "$(printf 'rule audit: 1 violation(s)\n- .claude/rules/probe.md: r — BAD → say GOOD')" "the finding detail"
  assert_eq "$(sessions)" "audit fix verify " "a finding that comes back unchanged stops the rounds"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "an unresolved finding committed"
  if tail -n 1 "$rule" | grep -q "audited"; then
    die "an unresolved finding stamped the rule"
  fi
  commit_json .detail | grep -qx "stopped: round 1 found the same findings as the round before" ||
    die "a refusal did not say why the rounds stopped"
  local review_log
  review_log="$(commit_json .detail | sed -n 's/^review log: //p')"
  [ -f "$review_log/round-0-findings.json" ] && [ -f "$review_log/round-1-findings.json" ] &&
    [ -f "$review_log/round-1-fixed.txt" ] || die "the review log is missing a round"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT=none -- main "$msg"
  assert_eq "$(commit_json .detail)" "rule audit: the auditor session never submitted a verdict" "no verdict"
}

test_commit_stops() {
  say "commit names why its rule review stopped"
  local repo origin rule msg finding missed="" noclaude dirs dir
  commit_setup

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good FAKE_VERIFY_SEQ="1 2 3 4 5 6 7 8 9 10" -- main "$msg"
  commit_json .detail | grep -qx "stopped: ran 10 rounds" || missed+=" [ran out of rounds]"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT='[{"file":"notes.md","requirement":"r","offending":"BAD","fix":"f"}]' -- main "$msg"
  commit_json .detail | grep -qx "stopped: the fix in round 1 failed or named no file it may change" ||
    missed+=" [fix named no rule]"

  commit_case
  printf '# Probe\n\nA BAD rule.\n' >"$rule"
  commit FAKE_AUDIT="$finding" FAKE_FIX=good FAKE_VERIFY=none -- main "$msg"
  commit_json .detail | grep -qx "stopped: the review in round 1 submitted no verdict" || missed+=" [no recheck verdict]"

  commit_case
  printf '# Probe\n\nA probe rule.\n' >"$rule"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$repo/bin/stamp-rules"
  commit -- main "$msg"
  [ "$(commit_json .detail)" = "rule audit: clean, but minting the audit stamp failed" ] || missed+=" [stamp failed]"

  commit_case
  printf '# Probe\n\nA probe rule.\n' >"$rule"
  printf 'junk' >"$repo/.git/index"
  commit -- main "$msg"
  [ "$(tail -n 1 "${LAST_LOG}" | jq -r .detail)" = "rule audit: could not read the working tree's rule edits" ] ||
    missed+=" [unreadable tree]"

  commit_case
  printf '# Probe\n\nA probe rule.\n' >"$rule"
  noclaude=""
  IFS=: read -r -a dirs <<<"$PATH"
  for dir in "${dirs[@]}"; do
    [ -x "$dir/claude" ] || noclaude+="${noclaude:+:}$dir"
  done
  commit PATH="$noclaude" -- main "$msg"
  [ "$(commit_json .detail)" = "rule audit: claude is not installed, and an edited rule needs its review" ] ||
    missed+=" [no claude]"
  [ -z "$missed" ] || die "a stopped review did not say why:$missed"
}

test_commit_gate() {
  say "commit bounds the gate, pushes and commits from a worktree"
  local repo origin rule msg finding before pidfile tries=0 hurry patient host interrupted watch
  commit_setup

  commit_case
  pidfile="$WORK/slow-pid"
  mkdir -p "$repo/checks"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' "echo \"\$\$\" >\"$pidfile\"" 'exec sleep 30' >"$repo/checks/slow"
  chmod +x "$repo/checks/slow"
  patient="$WORK/patient"
  mkdir -p "$patient"
  cat >"$patient/sleep" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [ "\$1" = 1 ]; then
  until [ -s "$pidfile" ]; do /bin/sleep 0.05; done
fi
exec /bin/sleep "\$@"
EOF
  chmod +x "$patient/sleep"
  commit FLOW_CI_TIMEOUT_MS=1000 PATH="$patient:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .detail)" "gate timed out after 1s" "a slow bin/ci"
  [ -s "$pidfile" ] || die "the slow check never started"
  while ps -p "$(cat "$pidfile")" >/dev/null; do
    tries=$((tries + 1))
    [ "$tries" -le 50 ] || die "the timed-out bin/ci kept running"
    sleep 0.1
  done

  commit_case
  mkdir -p "$repo/checks"
  rm -f "$pidfile"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' "echo \"\$\$\" >\"$pidfile\"" 'exec sleep 30' >"$repo/checks/slow"
  chmod +x "$repo/checks/slow"
  watch=$((90000 + RANDOM))
  env PATH="$FAKE_CLAUDE:$PATH" FAKE_CLAUDE_LOG="$CLAUDE_LOG" FLOW_CI_TIMEOUT_MS="$((watch * 1000))" \
    "$repo/bin/commit" main "$msg" >/dev/null 2>&1 &
  interrupted=$!
  tries=0
  until [ -s "$pidfile" ]; do
    tries=$((tries + 1))
    [ "$tries" -le 100 ] || die "the gate under an interrupted bin/commit never started"
    sleep 0.1
  done
  kill -TERM "$interrupted"
  wait "$interrupted" || true
  tries=0
  while pgrep -f "sleep $watch\$" >/dev/null; do
    tries=$((tries + 1))
    [ "$tries" -le 50 ] || die "an interrupted bin/commit left its timeout watcher running"
    sleep 0.1
  done
  tries=0
  while ps -p "$(cat "$pidfile")" -o stat= | grep -qv '^Z'; do
    tries=$((tries + 1))
    [ "$tries" -le 50 ] || die "an interrupted bin/commit left its gate running"
    sleep 0.1
  done

  hurry="$WORK/hurry"
  mkdir -p "$hurry"
  cat >"$hurry/sleep" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[ "$1" != 300 ] || exit 0
exec /bin/sleep "$@"
EOF
  chmod +x "$hurry/sleep"
  commit_case
  mkdir -p "$repo/checks"
  printf '%s\n' '#!/usr/bin/env bash' 'sleep 1' >"$repo/checks/slow"
  chmod +x "$repo/checks/slow"
  commit FLOW_CI_TIMEOUT_MS= PATH="$hurry:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .detail)" "gate timed out after 300s" "bin/ci with no .ci-timeout"
  commit_case
  mkdir -p "$repo/checks"
  printf '%s\n' '#!/usr/bin/env bash' 'sleep 1' >"$repo/checks/slow"
  chmod +x "$repo/checks/slow"
  printf 'elsewhere 600\n' >"$repo/.ci-timeout"
  commit FLOW_CI_TIMEOUT_MS= PATH="$hurry:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .detail)" "gate timed out after 300s" "bin/ci with another machine's .ci-timeout line"
  host="$(hostname -s 2>/dev/null || hostname)"
  host="$(printf '%s\n' "$host" | sed -E 's/-[0-9]+$//')"
  printf '%s 600\n' "$host" >>"$repo/.ci-timeout"
  perl -pi -e 's/!= 300 \]/!= 1025 ]/' "$hurry/sleep"
  commit FLOW_CI_TIMEOUT_MS= PATH="$hurry:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .detail)" "gate timed out after 1025s" "bin/ci bounded by this machine's .ci-timeout line"
  commit_case
  mkdir -p "$repo/checks" "$repo/a" "$repo/b"
  printf '%s\n' '#!/usr/bin/env bash' 'sleep 1' >"$repo/checks/slow"
  chmod +x "$repo/checks/slow"
  printf '%s 600\n' "$host" >"$repo/a/.ci-timeout"
  printf '%s 100\n' "$host" >"$repo/b/.ci-timeout"
  perl -pi -e 's/!= 1025 \]/!= 1150 ]/' "$hurry/sleep"
  commit FLOW_CI_TIMEOUT_MS= PATH="$hurry:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .detail)" "gate timed out after 1150s" "bin/ci bounded by every app's .ci-timeout line"

  commit_case
  printf '\nMore.\n' >>"$repo/notes.md"
  git -C "$repo" remote set-url origin "$WORK/missing.git"
  before="$(git -C "$repo" rev-parse HEAD)"
  commit -- main "$msg"
  assert_eq "$(commit_json .step)" "push" "a failed push"
  commit_json .detail | grep -q "^push failed: " || die "no push detail"
  [ "$(git -C "$repo" rev-parse HEAD)" != "$before" ] || die "a failed push undid the commit"

  commit_case
  git -C "$repo" worktree add -q "$repo/.worktrees/feat" -b feat
  printf 'feat\n' >"$repo/.worktrees/feat/feat.txt"
  before="$(git -C "$repo" rev-parse HEAD)"
  commit -- feat "$msg"
  assert_rc 0 "a worktree commit"
  assert_eq "$(git -C "$origin" rev-parse feat)" "$(commit_json .sha)" "the worktree push"
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "the worktree commit landed in the root"
}

test_commit_failures() {
  say "commit caps the gate's output and reports a refused git commit"
  local repo origin rule msg finding size
  commit_setup

  commit_case
  printf '%s\n' '#!/usr/bin/env bash' 'head -c 300000 /dev/zero | tr "\0" "x"' 'echo' 'echo END-OF-CI' 'exit 1' \
    >"$repo/bin/ci"
  echo "more" >>"$repo/notes.md"
  commit -- main "$msg"
  assert_eq "$(commit_json .step)" "ci" "a failing gate"
  size="$(commit_json .detail | wc -c | tr -d ' ')"
  [ "$size" -le 262145 ] || die "bin/commit passed on $size bytes of the gate's output"
  commit_json .detail | grep -x "END-OF-CI" >/dev/null || die "the capped gate output lost its end"

  commit_case
  echo "more" >>"$repo/notes.md"
  mkdir -p "$repo/refusing-hooks"
  printf '%s\n' '#!/usr/bin/env bash' 'echo hook-refused >&2' 'exit 1' >"$repo/refusing-hooks/pre-commit"
  chmod +x "$repo/refusing-hooks/pre-commit"
  git -C "$repo" config core.hooksPath refusing-hooks
  commit -- main "$msg"
  assert_eq "$(commit_json .step)" "commit" "a refused git commit"
  commit_json .detail | grep -q "commit failed:" || die "a refused git commit was not reported"
  commit_json .detail | grep -q "hook-refused" || die "a refused git commit lost git's reason"

  commit_case
  echo "more" >>"$repo/notes.md"
  cat >"$repo/bin/ci" <<'EOF'
#!/usr/bin/env bash
touch "$(git rev-parse --git-path index.lock)"
EOF
  commit -- main "$msg"
  assert_eq "$(commit_json .step)" "commit" "a stage that failed"
  commit_json .detail | grep -q "^stage failed:" || die "a failed stage was not reported"
  commit_json .detail | grep -q "index.lock" || die "a failed stage lost git's reason"

  commit_case
  echo "more" >>"$repo/notes.md"
  mkdir -p "$WORK/diff-fails"
  cat >"$WORK/diff-fails/git" <<EOF
#!/usr/bin/env bash
[ "\$*" != "diff --cached --quiet" ] || exit 128
exec "$(command -v git)" "\$@"
EOF
  chmod +x "$WORK/diff-fails/git"
  commit PATH="$WORK/diff-fails:$FAKE_CLAUDE:$PATH" -- main "$msg"
  assert_eq "$(commit_json .step)" "commit" "a staged diff git could not read"
  assert_eq "$(commit_json .detail)" "could not read the staged diff — git failed; nothing was committed" \
    "a staged diff git could not read"
}
