#!/usr/bin/env bash

SPIN_PID=

spin_label() {
  local label="$1" i=0 frames="|/-\\"
  while :; do
    printf '\rbin/ci: %s %s ' "$label" "${frames:i++%4:1}"
    sleep 0.1
  done
}

stop_spin() {
  local mark="${1:-}"
  if [ -n "${SPIN_PID:-}" ]; then
    kill "$SPIN_PID" 2>/dev/null || true
    wait "$SPIN_PID" 2>/dev/null || true
    SPIN_PID=
    if [ -n "$mark" ] && [ -n "${SAY:-}" ]; then
      if [ -t 1 ]; then
        printf '\rbin/ci: %s %s\033[K\n' "$SAY" "$mark"
      else
        printf 'bin/ci: %s %s\n' "$SAY" "$mark"
      fi
    fi
  fi
}

say() {
  stop_spin "✓"
  SAY="$1"
  if [ -t 1 ]; then
    spin_label "$SAY" &
    SPIN_PID=$!
  else
    printf 'bin/ci: %s\n' "$SAY"
  fi
}

die() {
  stop_spin "✗"
  echo "FAIL: ${SAY:-suite}: $*" >&2
  if [ -n "${LAST_LOG:-}" ] && [ -f "${LAST_LOG}" ]; then
    echo "----- log -----" >&2
    cat "${LAST_LOG}" >&2
  fi
  local kept
  if [ -n "${KEEP:-}" ] && [ -d "$KEEP" ] && kept="$(mktemp -d "${TMPDIR:-/tmp}/bin-stubs-fixture.XXXXXX")" &&
    mv "$KEEP" "$kept/"; then
    echo "fixture: $kept/${KEEP##*/}" >&2
  fi
  exit 1
}

keep() { KEEP="$1"; }

run_log() {
  if [ -n "${WORK:-}" ] && [ -n "${BASHPID:-}" ]; then
    RUN_LOGS=$((${RUN_LOGS:-0} + 1))
    LAST_LOG="$WORK/run-log.$BASHPID.$RUN_LOGS"
  else
    LAST_LOG="$(mktemp "${TMPDIR:-/tmp}/bin-stubs-log.XXXXXX")"
  fi
  if "$@" >"${LAST_LOG}" 2>&1; then
    LAST_RC=0
  else
    LAST_RC=$?
  fi
}

assert_rc() {
  [ "${LAST_RC}" -eq "$1" ] || die "exit ${LAST_RC}, expected $1 — ${2:-command}"
}

assert_eq() {
  [ "$1" = "$2" ] || die "expected [$2] got [$1]${3:+ — $3}"
}

row_of() {
  awk -v n="$1" '$1 == n { gsub(/\r/, "", $3); print $3; exit }' <<<"$2"
}

copy_dir() {
  mkdir -p "$2"
  cp -cR "$1/." "$2/" 2>/dev/null || cp -R "$1/." "$2/"
}

stub_suite() {
  mkdir -p "$1/tests"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' >"$1/tests/run"
  cp "$1/tests/run" "$1/tests/guards"
  chmod +x "$1/tests/run" "$1/tests/guards"
}

sentinel_file() {
  printf '%s\n' "$1/.flow-states/main/ci-sentinel"
}

litter() { printf '%s\n' "$1" >>"$WORK/litter"; }

sweep_work() {
  local path
  while IFS= read -r path; do
    rm -f "$path"
  done < <(find "$WORK" -name litter -type f -exec cat {} + 2>/dev/null)
  rm -rf "$WORK"
}

start_work() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/bin-stubs-tests.XXXXXX")"
  export NODE_COMPILE_CACHE="$WORK/node-compile-cache"
  trap 'stop_spin; sweep_work' EXIT
  set -o errtrace
  trap 'echo "FAIL: ${SAY:-suite}: line $LINENO exited $?: $BASH_COMMAND" >&2' ERR
}

new_repo() {
  local d
  d="$(mktemp -d "$WORK/repo.XXXXXX")"
  git -C "$d" init -q -b main
  printf '[user]\n\temail = bin-stubs@example.com\n\tname = bin-stubs\n' >>"$d/.git/config"
  cat >"$d/.gitignore" <<'EOF'
.flow-states/
node_modules/
.venv/
vendor/
target/
.build/
dist/
build/
coverage/
.bundle/
EOF
  git -C "$d" add .gitignore
  git -C "$d" commit -q -m init
  printf '%s\n' "$d"
}

expect_ok() {
  run_log "$@"
  assert_rc 0 "$*"
}

expect_fail() {
  run_log "$@"
  [ "${LAST_RC}" -ne 0 ] || die "expected failure: $*"
}

summary() { tail -n 20 "${LAST_LOG}"; }

run_all() {
  local logs="$1" runner="$2" name rc failed=0 i=0 pids=()
  shift 2
  mkdir -p "$logs"
  for name in "$@"; do
    "$runner" "$name" >"$logs/$name" 2>&1 &
    pids+=("$!")
  done
  for name in "$@"; do
    rc=0
    wait "${pids[$i]}" || rc=$?
    i=$((i + 1))
    cat "$logs/$name"
    [ "$rc" -eq 0 ] || failed=1
  done
  return "$failed"
}
