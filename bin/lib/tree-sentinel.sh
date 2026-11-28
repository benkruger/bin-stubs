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
  local f base="${GATE_LIB%/*}" driver files=()
  driver="${GATE_DRIVER#"$base"}"
  driver="${driver#/}"
  while IFS= read -r -d '' f; do
    [ -f "$base/$f" ] && files+=("$f")
  done < <(git -C "$base" ls-files -z --cached --others --exclude-standard -- "${GATE_LIB#"$base"/}" \
    "${driver:-.}" | LC_ALL=C sort -zu)
  [ "${#files[@]}" -gt 0 ] || return 0
  paste -d ' ' <(printf '%s\n' "${files[@]}") <(cd "$base" && git hash-object -- "${files[@]}")
}

GATE_PRINT=""
[ "${ROOT_APP:-0}" = 1 ] || GATE_PRINT="$(gate_fingerprint)"

ANCESTOR_NAMES=()
case "${GATE_DRIVER##*/}" in
  _shell) ANCESTOR_NAMES=(.shellcheckrc shellcheckrc) ;;
  _ios) ANCESTOR_NAMES=(.swift-format) ;;
  _rust) ANCESTOR_NAMES=(rustfmt.toml .rustfmt.toml clippy.toml .clippy.toml .cargo/config.toml .cargo/config) ;;
  _typescript)
    ANCESTOR_NAMES=(eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts eslint.config.mts
      eslint.config.cts package.json package.yaml .editorconfig .prettierrc .prettierrc.json .prettierrc.yaml
      .prettierrc.yml .prettierrc.json5 .prettierrc.js .prettierrc.mjs .prettierrc.cjs .prettierrc.ts .prettierrc.mts
      .prettierrc.cts .prettierrc.toml prettier.config.js prettier.config.mjs prettier.config.cjs prettier.config.ts
      prettier.config.mts prettier.config.cts)
    ;;
  _javascript) ANCESTOR_NAMES=(biome.json biome.jsonc .editorconfig) ;;
  _python)
    ANCESTOR_NAMES=(pyproject.toml ruff.toml .ruff.toml uv.toml pytest.ini .pytest.ini pytest.toml .pytest.toml
      tox.ini setup.cfg mypy.ini .mypy.ini conftest.py)
    ;;
  _rails) ANCESTOR_NAMES=(.rubocop.yml) ;;
esac

ancestor_configs() {
  local dir up="" name sum
  dir="$(pwd -P)"
  while [ -n "$dir" ]; do
    dir="${dir%/*}"
    up="../$up"
    for name in "${ANCESTOR_NAMES[@]+"${ANCESTOR_NAMES[@]}"}"; do
      [ -f "$dir/$name" ] || continue
      sum="$(git hash-object --no-filters -- "$dir/$name")" || return 1
      printf '%s%s %s\n' "$up" "$name" "$sum"
    done
  done
}

untracked_kept() {
  local path name skip
  while IFS= read -r -d '' path; do
    [ -f "$path" ] || [ -L "$path" ] || continue
    case "$path" in
      .flow-states/* | .venv/* | node_modules/* | target/* | .build/*) continue ;;
    esac
    skip=0
    for name in "$@"; do
      case "$path" in
        "$name" | "$name"/*)
          skip=1
          break
          ;;
      esac
    done
    [ "$skip" -eq 1 ] || printf '%s\0' "$path"
  done
}

content_tree() {
  local dir real prefix tree rc=0
  dir="$(mktemp -d "${TMPDIR:-/tmp}/bin-lib-tree-sentinel.XXXXXX")"
  trap 'rm -rf "$dir"' EXIT
  trap 'exit 130' INT TERM HUP
  real="$(git rev-parse --path-format=absolute --git-path index)" || rc=$?
  [ "$rc" -ne 0 ] || [ ! -f "$real" ] || cp "$real" "$dir/index" || rc=$?
  prefix="$(git rev-parse --show-prefix)" || rc=$?
  if [ "$rc" -eq 0 ]; then
    GIT_INDEX_FILE="$dir/index" git add -u &&
      git ls-files -z --others --exclude-standard -- . | untracked_kept "$@" |
      GIT_INDEX_FILE="$dir/index" git update-index --add -z --stdin &&
      GIT_INDEX_FILE="$dir/index" git rm -r -q --cached --ignore-unmatch -- ':(glob)**/.ci-timeout' "$@" &&
      tree="$(GIT_INDEX_FILE="$dir/index" git write-tree ${prefix:+"--prefix=$prefix"})" || rc=$?
  fi
  rm -rf "$dir"
  trap - EXIT INT TERM HUP
  [ "$rc" -eq 0 ] || return "$rc"
  printf '%s\n' "$tree"
}

root_app_fingerprint() {
  local d excludes=()
  for d in ./*/; do
    [ -d "$d" ] || continue
    if is_app_dir "$d"; then
      d="${d%/}"
      excludes+=("${d#./}")
    fi
  done
  content_tree "${excludes[@]+"${excludes[@]}"}" CLAUDE.md README.md .claude checks
}

tree_fingerprint() {
  if [ "${ROOT_APP:-0}" = 1 ]; then
    root_app_fingerprint || return
  else
    content_tree || return
    [ -z "$GATE_PRINT" ] || printf '%s\n' "$GATE_PRINT"
  fi
  ancestor_configs
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
