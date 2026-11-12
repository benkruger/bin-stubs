#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> passes when the selected Xcode is
# the version pinned in <root>/.xcode-version (the file xcodes reads), and
# explains the fix otherwise.

toolchain_check() {
  local root="$1" pinned active
  if [ ! -f "$root/.xcode-version" ]; then
    echo "toolchain: .xcode-version is missing; pin Xcode with: xcodebuild -version | head -n 1 | cut -d' ' -f2 > .xcode-version" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.xcode-version")"
  if ! active="$(xcodebuild -version 2>/dev/null | head -n 1 | cut -d' ' -f2)" || [ -z "$active" ]; then
    echo "toolchain: Xcode is not selected; .xcode-version pins $pinned (xcodes select $pinned)" >&2
    return 1
  fi
  case "$active" in
    "$pinned" | "$pinned".*) ;;
    *)
      echo "toolchain: Xcode $active is selected but .xcode-version pins $pinned; switch with: xcodes select $pinned" >&2
      return 1
      ;;
  esac
}
