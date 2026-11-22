#!/usr/bin/env bash

# shellcheck source=apps.sh
. "$(dirname "${BASH_SOURCE[0]}")/apps.sh"
GATE_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE_DRIVER="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"

gate_fingerprint() {
  local f
  while IFS= read -r f; do
    printf '%s ' "${f#"$(dirname "$GATE_LIB")"/}"
    git hash-object -- "$f"
  done < <(find "$GATE_LIB" "$GATE_DRIVER" -type f | LC_ALL=C sort -u)
}

root_app_fingerprint() {
  local name path d skip e
  local excludes=()
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
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      skip=0
      for e in "${excludes[@]}"; do
        if [ "$name" = "$e" ]; then
          skip=1
          break
        fi
      done
      [ "$skip" -eq 1 ] && continue
      printf '%s %s\n' "$name" "$(git rev-parse "HEAD:$name" 2>/dev/null || echo missing)"
    done < <(git ls-tree --name-only HEAD)
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
    printf '%s\0' "$path"
    git hash-object "$path"
  done < <(git ls-files --others --exclude-standard -z -- "${spec[@]}")
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
  gate_fingerprint
}

tree_hash() {
  tree_fingerprint | shasum -a 256 | cut -d' ' -f1
}
