#!/usr/bin/env bash

STEP_NAMES=()
STEP_PIDS=()
STEP_LOGS=()

steps_init() {
  STEPS_DIR="$1"
  STEPS_FORCE="$2"
  STEPS_HASH="$3"
  STEPS_LOG="$4"
  STEPS_BRANCH="$5"
  STEPS_WARNINGS="$6"
  STEPS_ELIDE="$7"
}

start_step() {
  local name="$1" step_log
  shift
  STEP_NAMES+=("$name")
  if [ "$STEPS_FORCE" -eq 0 ] && [ -f "$STEPS_DIR/ci-$name-sentinel" ] &&
    [ "$(cat "$STEPS_DIR/ci-$name-sentinel")" = "$STEPS_HASH" ]; then
    STEP_PIDS+=("")
    STEP_LOGS+=("")
    return 0
  fi
  step_log="$(mktemp)"
  "$@" >"$step_log" 2>&1 &
  STEP_PIDS+=("$!")
  STEP_LOGS+=("$step_log")
}

steps_spin() {
  local spin_label="$1" i=0 frames="|/-\\"
  while :; do
    printf '\rbin/ci: %s %s ' "$spin_label" "${frames:i++%4:1}"
    sleep 0.1
  done
}

finish_steps() {
  local i name label rc mark sp failed=()
  for i in "${!STEP_NAMES[@]}"; do
    name="${STEP_NAMES[$i]}"
    label="[$((i + 1))/${#STEP_NAMES[@]}] $name"
    if [ -z "${STEP_PIDS[$i]}" ]; then
      echo "bin/ci: $label ✓ (unchanged since it passed)"
      continue
    fi
    sp=""
    if [ -t 1 ]; then
      steps_spin "$label" &
      sp=$!
    fi
    rc=0
    wait "${STEP_PIDS[$i]}" || rc=$?
    if [ -n "$sp" ]; then
      kill "$sp" 2>/dev/null || true
      wait "$sp" 2>/dev/null || true
      printf '\r\033[K'
    fi
    cat "${STEP_LOGS[$i]}" >>"$STEPS_LOG"
    if [ "$rc" -eq 0 ] && [ -n "$STEPS_WARNINGS" ] && grep -qiE "$STEPS_WARNINGS" "${STEP_LOGS[$i]}"; then
      echo "bin/ci: step '$name' printed a warning (above); a warning fails the gate" >>"$STEPS_LOG"
      rc=1
    fi
    rm -f "${STEP_LOGS[$i]}"
    mark="✓"
    if [ "$rc" -eq 0 ]; then
      mkdir -p "$STEPS_DIR"
      printf '%s\n' "$STEPS_HASH" >"$STEPS_DIR/ci-$name-sentinel"
    else
      mark="✗"
      failed+=("$name")
    fi
    echo "bin/ci: $label $mark"
  done
  [ "${#failed[@]}" -gt 0 ] || return 0
  if [ -n "$STEPS_ELIDE" ]; then
    grep -v "$STEPS_ELIDE" "$STEPS_LOG" >&2 || true
  else
    cat "$STEPS_LOG" >&2
  fi
  for name in "${failed[@]}"; do
    echo "bin/ci: gate RED ($STEPS_BRANCH) — step '$name' failed (above${STEPS_ELIDE:+; 100%-covered rows elided})." >&2
  done
  return 1
}
