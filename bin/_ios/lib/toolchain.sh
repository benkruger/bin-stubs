#!/usr/bin/env bash

toolchain_check() {
  local root="$1" pinned active
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if [ ! -f "$root/.xcode-version" ]; then
    echo "toolchain: .xcode-version is missing; pin Xcode with: xcodebuild -version | awk 'NR == 1 { print \$2 }' > .xcode-version" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.xcode-version")"
  if ! active="$(xcodebuild -version 2>/dev/null | awk 'NR == 1 { print $2 }')" || [ -z "$active" ]; then
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

packages_check() {
  local root="$1"
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if grep -qs XCRemoteSwiftPackageReference "$root"/*.xcodeproj/project.pbxproj &&
    [ ! -d "$root/.build/xcode-packages/checkouts" ]; then
    echo "packages: Swift packages are not fetched; run bin/dependencies" >&2
    return 1
  fi
  [ -f "$root/Package.resolved" ] || return 0
  if [ ! -f "$root/.build/workspace-state.json" ] || [ "$root/Package.resolved" -nt "$root/.build/workspace-state.json" ]; then
    echo "packages: Swift packages are not fetched; run bin/dependencies" >&2
    return 1
  fi
}
