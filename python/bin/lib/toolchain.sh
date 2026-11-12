#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> passes when uv finds an installed
# Python matching <root>/.python-version (uv uses the same file for every
# run), and explains the fix otherwise.

toolchain_check() {
  local root="$1" pinned python active
  if [ ! -f "$root/.python-version" ]; then
    echo "toolchain: .python-version is missing; pin Python with: uv python pin <version>" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.python-version")"
  if ! python="$(cd "$root" && uv python find 2>/dev/null)"; then
    echo "toolchain: no installed Python matches .python-version ($pinned); install it with: uv python install $pinned" >&2
    return 1
  fi
  active="$("$python" -c 'import platform; print(platform.python_version())')"
  case "$active" in
    "$pinned" | "$pinned".*) ;;
    *)
      echo "toolchain: Python $active is active but .python-version pins $pinned" >&2
      return 1
      ;;
  esac
}
