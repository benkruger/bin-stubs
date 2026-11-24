#!/usr/bin/env bash

GATE_LIB="${BASH_SOURCE[0]%/*}"
[ "$GATE_LIB" != "${BASH_SOURCE[0]}" ] || GATE_LIB=.
GATE_DRIVER="${BASH_SOURCE[1]%/*}"
[ "$GATE_DRIVER" != "${BASH_SOURCE[1]}" ] || GATE_DRIVER=.
# shellcheck source=apps.sh
. "${GATE_LIB:-/}/apps.sh"
GATE_LIB="$(cd "${GATE_LIB:-/}" && pwd)"
GATE_DRIVER="$(cd "${GATE_DRIVER:-/}" && pwd)"

gate_fingerprint() {
  local f base="${GATE_LIB%/*}" files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$GATE_LIB" "$GATE_DRIVER" -type f | LC_ALL=C sort -u)
  [ "${#files[@]}" -gt 0 ] || return 0
  paste -d ' ' <(printf '%s\n' "${files[@]#"$base"/}") <(git hash-object -- "${files[@]}")
}

GATE_PRINT=""
[ "${ROOT_APP:-0}" = 1 ] || GATE_PRINT="$(gate_fingerprint)"

root_app_fingerprint() {
  local name path d skip e meta i
  local excludes=() paths=() hashes=()
  local top="$PWD"
  for d in "$top"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    if is_app_dir "$d"; then
      excludes+=("$name")
    fi
  done
  excludes+=(CLAUDE.md .claude checks tests .ci-timeout)
  local spec=(.)
  for name in "${excludes[@]}"; do
    spec+=(":!$name")
  done
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    while IFS=$'\t' read -r meta name; do
      [ -z "$name" ] && continue
      skip=0
      for e in "${excludes[@]}"; do
        if [ "$name" = "$e" ]; then
          skip=1
          break
        fi
      done
      [ "$skip" -eq 1 ] && continue
      printf '%s %s\n' "$name" "${meta##* }"
    done < <(git ls-tree HEAD)
    git diff --relative HEAD -- "${spec[@]}"
    git diff --relative --cached -- "${spec[@]}"
  else
    echo "untracked-subtree"
  fi
  while IFS= read -r -d '' path; do
    [ -f "$path" ] || continue
    case "$path" in
      .flow-states/* | .venv/* | node_modules/* | vendor/* | target/* | .build/*) continue ;;
    esac
    skip=0
    for e in "${excludes[@]}"; do
      case "$path" in
        "$e" | "$e"/*)
          skip=1
          break
          ;;
      esac
    done
    [ "$skip" -eq 1 ] && continue
    paths+=("$path")
  done < <(git ls-files --others --exclude-standard -z -- "${spec[@]}")
  [ "${#paths[@]}" -gt 0 ] || return 0
  while IFS= read -r meta; do
    hashes+=("$meta")
  done < <(git hash-object -- "${paths[@]}")
  for i in "${!paths[@]}"; do
    printf '%s\0%s\n' "${paths[$i]}" "${hashes[$i]}"
  done
}

tree_fingerprint() {
  if [ "${ROOT_APP:-0}" = 1 ]; then
    root_app_fingerprint
    return
  fi
  local not_timeout=':(exclude,glob)**/.ci-timeout'
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git ls-tree -r HEAD -- . | awk -F'\t' '$2 !~ /(^|\/)\.ci-timeout$/'
    git diff --relative HEAD -- . "$not_timeout"
    git diff --relative --cached -- . "$not_timeout"
  else
    echo "untracked-subtree"
  fi
  local f
  local paths=()
  while IFS= read -r -d '' f; do
    [ -f "$f" ] || continue
    case "$f" in
      .flow-states/* | .venv/* | node_modules/* | vendor/* | target/* | .build/*) continue ;;
    esac
    paths+=("$f")
  done < <(git ls-files --others --exclude-standard -z -- . "$not_timeout")
  if [ "${#paths[@]}" -gt 0 ]; then
    printf '%s\0' "${paths[@]}"
    git hash-object -- "${paths[@]}"
  fi
  [ -z "$GATE_PRINT" ] || printf '%s\n' "$GATE_PRINT"
}

tree_hash() {
  local sum
  if command -v sha256sum >/dev/null 2>&1; then
    sum="$(tree_fingerprint | sha256sum)" || return
  else
    sum="$(tree_fingerprint | shasum -a 256)" || return
  fi
  printf '%s\n' "${sum%% *}"
}
