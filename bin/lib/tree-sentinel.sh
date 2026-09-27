#!/usr/bin/env bash
# Fingerprint the working tree for one gate.
# Source this from the directory the sentinel guards. Do not execute it.
#
# The hash covers the committed subtree, both diffs, and every untracked
# regular file. Dependency trees and the sentinel directory are left out.
# Untracked files are hashed in one git hash-object batch. A symlink is
# skipped before that batch, because git hash-object cannot hash it.

root_app_fingerprint() {
  local name path d skip e
  local excludes=()
  local top="$PWD"
  for d in "$top"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    if [ -x "${d}bin/ci" ]; then
      excludes+=("$name")
    fi
  done
  excludes+=(CLAUDE.md .claude checks tests)
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
        "$e" | "$e"/*) skip=1; break ;;
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
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git rev-parse 'HEAD:./' 2>/dev/null || echo "untracked-subtree"
    git diff --relative HEAD -- .
    git diff --relative --cached -- .
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
  done < <(git ls-files --others --exclude-standard -z -- .)
  if [ "${#paths[@]}" -gt 0 ]; then
    printf '%s\0' "${paths[@]}"
    git hash-object -- "${paths[@]}"
  fi
}

tree_hash() {
  tree_fingerprint | shasum -a 256 | cut -d' ' -f1
}
