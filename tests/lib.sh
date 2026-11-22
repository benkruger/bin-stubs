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
  if [ -n "${KEEP:-}" ]; then
    echo "fixture: ${KEEP}" >&2
  fi
  exit 1
}

run_log() {
  LAST_LOG="$(mktemp)"
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
  cp -R "$1/." "$2/"
}

sentinel_file() {
  printf '%s\n' "$1/.flow-states/main/ci-sentinel"
}

start_work() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/bin-stubs-tests.XXXXXX")"
  trap 'stop_spin; rm -rf "$WORK"' EXIT
  set -o errtrace
  trap 'echo "FAIL: ${SAY:-suite}: line $LINENO exited $?: $BASH_COMMAND" >&2' ERR
}

new_repo() {
  local d
  d="$(mktemp -d "$WORK/repo.XXXXXX")"
  git -C "$d" init -q -b main
  git -C "$d" config user.email "bin-stubs@example.com"
  git -C "$d" config user.name "bin-stubs"
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
