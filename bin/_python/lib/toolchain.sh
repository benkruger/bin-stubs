#!/usr/bin/env bash

export UV_PYTHON_DOWNLOADS=never

toolchain_check() {
  local root="$1" pinned python active version
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if [ ! -f "$root/.python-version" ]; then
    echo "toolchain: .python-version is missing; pin Python with: uv python pin <version>" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.python-version")"
  if ! python="$(cd "$root" && uv python find 2>/dev/null)"; then
    echo "toolchain: no installed Python matches .python-version ($pinned); install it with: uv python install $pinned" >&2
    return 1
  fi
  [[ "$pinned" =~ ^[^0-9\<\>=!~,]*([0-9]+(\.[0-9]+)*) ]] || return 0
  version="${BASH_REMATCH[1]}"
  active="$("$python" --version)"
  active="${active#Python }"
  case "$active" in
    "$version" | "$version".*) ;;
    *)
      echo "toolchain: Python $active is active but .python-version pins $pinned" >&2
      return 1
      ;;
  esac
}

packages_check() {
  local root="$1"
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if ! (cd "$root" && uv sync --locked --offline --check >/dev/null 2>&1); then
    echo "packages: .venv or uv.lock does not match pyproject.toml; run bin/dependencies" >&2
    return 1
  fi
}
