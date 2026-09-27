#!/usr/bin/env bash
# Sentinel conductor for one app. Sourced by bin/ci after it has set
# `here`, `root`, and `label` and cd'd to `root`. Do not execute it.
#
# A matching fingerprint exits green before the four leaves. A green run
# stores a new fingerprint taken after the leaves, because format rewrites
# files. A red run leaves the previous certificate in place.
#
# Placed at bin/_root, the fingerprint is the repo minus every sibling
# folder that has its own bin/ci, and minus the corpus paths. Placed at
# <app>/bin, the fingerprint is that folder only.

force=0
clean=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --clean) clean=1 ;;
    *)
      echo "bin/ci: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
case "$branch" in
  "" | "." | "..")
    echo "bin/ci: refusing to build a sentinel path for unsafe branch: '$branch'" >&2
    exit 2
    ;;
esac

sentinel="$root/.flow-states/$branch/ci-sentinel"

if [ "$clean" -eq 1 ]; then
  rm -f "$sentinel"
  echo "bin/ci: cleaned sentinel for $branch"
  exit 0
fi

# shellcheck source=tree-sentinel.sh
. "$here/lib/tree-sentinel.sh"

root_app_fingerprint() {
  local name path d skip e
  local excludes=()
  for d in "$root"/*/; do
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

fingerprint() {
  if [ "$(basename "$here")" = "_root" ]; then
    root_app_fingerprint
  else
    tree_fingerprint
  fi
}

hash_now() {
  fingerprint | shasum -a 256 | cut -d' ' -f1
}

pre_hash="$(hash_now)"
if [ "$force" -eq 0 ] && [ -f "$sentinel" ] && [ "$(cat "$sentinel")" = "$pre_hash" ]; then
  exit 0
fi

echo ""
echo "═══ ${label} ════════════════════════════════════"

if [ -x "$here/ensure-deps" ]; then
  "$here/ensure-deps"
fi

"$here/format" --all
"$here/lint" --all
"$here/build"
"$here/test"

mkdir -p "$(dirname "$sentinel")"
hash_now >"$sentinel"
echo "bin/ci: gate green ($branch) — sentinel written."
