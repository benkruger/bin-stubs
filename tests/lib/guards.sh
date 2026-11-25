#!/usr/bin/env bash

plant_bad_rules() {
  local rules="$1/.claude/rules"
  {
    printf '# Wide\n\n'
    head -c 8100 /dev/zero | tr '\0' 'a'
    printf '\n'
  } >"$rules/wide.md"
  {
    printf '# Narrow\n\n'
    for _ in $(seq 1 30); do printf '%100s\n' '' | sed 's/ /✓/g'; done
  } >"$rules/narrow.md"
  printf '## Lead\n\n# Late\n' >"$rules/late.md"
  printf '# One\n\n# Two\n' >"$rules/twice.md"
  printf '# Old\n\nThis rule %s apply.\n' "used to" >"$rules/old.md"
  printf -- '---\nname: front\n---\n\n# Front\n' >"$rules/front.md"
  printf '# Story\n\n## %s\n\nText.\n' Why >"$rules/story.md"
  printf '# Cite\n\nSee \x60%s\x60, \x60%s\x60 and \x60%s\x60.\n' nowhere.md starter/.claude/rules/gone.md \
    .claude/rules/cite.md >"$rules/cite.md"
}

check_bad_rules() {
  local msg missed=""
  for msg in "wide.md: 8109 characters (cap 8000)" "late.md: does not lead with an H1" "twice.md: 2 H1 headings (want 1)" \
    "old.md: backward-facing wording" "front.md: frontmatter" "story.md: narrative heading" \
    "cite.md: cites missing nowhere.md" "cite.md: cites missing starter/.claude/rules/gone.md"; do
    grep -qxF "guards: .claude/rules/$msg" "${LAST_LOG}" || missed+=" [$msg]"
  done
  [ -z "$missed" ] || die "a rule's shape was not checked:$missed"
  ! grep -qE "narrow\.md: [0-9]+ (characters|lines)" "${LAST_LOG}" || die "a rule's cap counted bytes, not characters"
  ! grep -qF "cites missing .claude/rules/cite.md" "${LAST_LOG}" || die "a rule citing a path that exists was failed"
}

plant_bad_claude() {
  {
    printf 'Read .claude/rules/probe.md first; it %s differ.\n' "used to"
    for _ in $(seq 1 401); do printf -- '- a line padded out to thirty-one\n'; done
  } >"$1/CLAUDE.md"
}

check_bad_claude() {
  local msg missed=""
  for msg in "402 lines (cap 400)" "13688 characters (cap 12000)" "does not lead with an H1" "0 H1 headings (want 1)" \
    "backward-facing wording" "points at the rules directory" "names the rule probe.md"; do
    grep -qxF "guards: CLAUDE.md: $msg" "${LAST_LOG}" || missed+=" [$msg]"
  done
  [ -z "$missed" ] || die "CLAUDE.md was not checked:$missed"
}

bare_guards() {
  local repo
  repo="$(new_repo)"
  mkdir -p "$repo/tests"
  cp "$HERE/../starter/tests/guards" "$repo/tests/guards"
  printf '%s\n' "$repo"
}

check_bad_settings() {
  local msg missed=""
  for msg in ".claude/settings.json: does not allow Bash(bin/*)" \
    ".claude/settings.json: no PreToolUse hook runs .claude/hooks/require-bin" \
    ".claude/hooks/session-start is missing or not executable"; do
    grep -qxF "guards: $msg" "${LAST_LOG}" || missed+=" [$msg]"
  done
  [ -z "$missed" ] || die "the settings were not checked:$missed"
}

test_bare_guards() {
  say "guards on a repo with no rules, CLAUDE.md or settings"
  local repo missed=""
  repo="$(bare_guards)"
  keep "$repo"
  expect_fail "$repo/tests/guards"
  grep -qx "guards: .claude/rules holds no rules" "${LAST_LOG}" || missed+=" [no rules]"
  grep -qx "guards: CLAUDE.md is missing" "${LAST_LOG}" || missed+=" [no CLAUDE.md]"
  grep -qx "guards: .claude/settings.json is missing" "${LAST_LOG}" || missed+=" [no settings]"
  mkdir -p "$repo/.claude"
  printf '{ bad\n' >"$repo/.claude/settings.json"
  expect_fail "$repo/tests/guards"
  grep -qx "guards: .claude/settings.json is not valid JSON" "${LAST_LOG}" || missed+=" [settings not JSON]"
  printf '{ "permissions": { "allow": "Bash(bin/*)" } }\n' >"$repo/.claude/settings.json"
  expect_fail "$repo/tests/guards"
  grep -qx "guards: .claude/settings.json: has a permissions.allow that is not a list" "${LAST_LOG}" ||
    missed+=" [allow not a list]"
  jq -n '{permissions: {allow: ["Bash(bin/*)", "Bash(tests/run)"], deny: "Bash(git commit *) Bash(git reset *)"},
    disableAllHooks: true,
    hooks: {PreToolUse: [
      {matcher: "Read", hooks: [{type: "command", command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/require-bin"}]},
      {matcher: "Bash", hooks: [{type: "prompt", command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/require-bin"}]}]}}' \
    >"$repo/.claude/settings.json"
  expect_fail "$repo/tests/guards"
  grep -qx "guards: .claude/settings.json: has a permissions.deny that is not a list" "${LAST_LOG}" ||
    missed+=" [deny not a list]"
  grep -qx "guards: .claude/settings.json: turns every hook off with disableAllHooks" "${LAST_LOG}" ||
    missed+=" [disableAllHooks]"
  grep -qx "guards: .claude/settings.json: no PreToolUse hook runs .claude/hooks/require-bin" "${LAST_LOG}" ||
    missed+=" [hook off Bash]"
  [ -z "$missed" ] || die "the guards passed a repo missing what they require:$missed"
}

test_guards_scans() {
  say "guards fail a scan that does not finish"
  local repo stubs="$WORK/broken-perl" missed=""
  repo="$(bare_guards)"
  keep "$repo"
  printf 'fn main() {}\n' >"$repo/main.rs"
  mkdir -p "$stubs"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$stubs/perl"
  chmod +x "$stubs/perl"
  run_log env PATH="$stubs:$PATH" "$repo/tests/guards"
  assert_rc 1 "guards whose perl scans die"
  grep -qx "guards: the comment scan did not finish" "${LAST_LOG}" || missed+=" [comment scan]"
  grep -qx "guards: the Rust attribute scan did not finish" "${LAST_LOG}" || missed+=" [Rust attribute scan]"
  [ -z "$missed" ] || die "the guards passed a scan that did not finish:$missed"
  scan_plants "$repo"
  failing_tool_stubs "$WORK/failing"
  failing_scans "$repo" "$WORK/failing" perl "byte cap" "file size"
  failing_scans "$repo" "$WORK/failing" perl "sh|bash" "bash script"
  failing_scans "$repo" "$WORK/failing" perl "entry point is not executable" "entry point"
  failing_scans "$repo" "$WORK/failing" perl "audited:" rule
  failing_scans "$repo" "$WORK/failing" grep "-nIHE -lE -nHE -Lw" suppression "skip candidate" "time limit" install \
    packages_check
  failing_scans "$repo" "$WORK/failing" grep "-nE -noE -LE" skip "matching line" "time limit value" update
}

scan_plants() {
  local repo="$1"
  mkdir -p "$repo/.claude/rules" "$repo/bin/_x/lib"
  printf '# Probe\n\nA probe rule.\n' >"$repo/.claude/rules/probe.md"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'npm install' >"$repo/bin/_x/build"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'npm install' >"$repo/bin/_x/dependencies"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' >"$repo/bin/_x/ci"
  printf '%s\n' '#!/usr/bin/env bash' '' 'packages_check() {' '  return 0' '}' >"$repo/bin/_x/lib/toolchain.sh"
  chmod +x "$repo/bin/_x/build" "$repo/bin/_x/dependencies" "$repo/bin/_x/ci"
  printf '{ "jest": { "testTimeout": 5 } }\n' >"$repo/package.json"
  printf 'test.skip("a", () => {});\ntest("b", () => {}, { timeout: limit });\n' >"$repo/a.test.ts"
}

failing_tool_stubs() {
  local stubs="$1" tool real
  mkdir -p "$stubs"
  for tool in perl grep; do
    real="$(command -v "$tool")"
    cat >"$stubs/$tool" <<EOF
#!/usr/bin/env bash
if [ "\${FAIL_TOOL:-}" = "$tool" ]; then
  if [ "$tool" = grep ]; then
    case " \$FAIL_ON " in
      *" \${1:-} "*) exit 2 ;;
    esac
  elif [ "\${1:-}" = - ]; then
    program="\$(cat)"
    case "\$program" in
      *"\$FAIL_ON"*) exit 1 ;;
    esac
    exec "$real" "\$@" <<<"\$program"
  else
    case "\$*" in
      *"\$FAIL_ON"*) exit 1 ;;
    esac
  fi
fi
exec "$real" "\$@"
EOF
    chmod +x "$stubs/$tool"
  done
}

failing_scans() {
  local repo="$1" stubs="$2" tool="$3" on="$4" label missed=""
  shift 4
  run_log env PATH="$stubs:$PATH" FAIL_TOOL="$tool" FAIL_ON="$on" "$repo/tests/guards"
  assert_rc 1 "guards whose $tool fails on $on"
  for label in "$@"; do
    grep -qx "guards: the $label scan did not finish" "${LAST_LOG}" || missed+=" [$label]"
  done
  [ -z "$missed" ] || die "the guards passed a scan that did not finish:$missed"
}
