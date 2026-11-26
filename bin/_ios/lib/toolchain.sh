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

pins_fetched() {
  jq -e -n --slurpfile resolved "$1" --slurpfile state "$2" '
    [$state[0].object.dependencies[]? | {ref: .packageRef, revision: .state.checkoutState.revision}] as $have
    | ([$have[] | {key: .ref.identity, value: .revision}] | from_entries) as $by_identity
    | ([$have[] | {key: (.ref.location // ""), value: .revision}] | from_entries) as $by_location
    | all(($resolved[0].pins // $resolved[0].object.pins // [])[];
      if .identity then $by_identity[.identity] == .state.revision
      else $by_location[.repositoryURL // ""] == .state.revision end)' >/dev/null 2>&1
}

package_identities() {
  perl -0777 -ne '
    my $pattern = $ARGV =~ /\.pbxproj\z/
      ? qr/repositoryURL\s*=\s*"([^"]+)"/
      : qr/\.package\s*\(\s*(?:name\s*:\s*"[^"]*"\s*,\s*)?url\s*:\s*"([^"]+)"/;
    while (/$pattern/g) {
      my $id = $1;
      $id =~ s{/+\z}{};
      $id =~ s{\.git\z}{};
      $id =~ s{.*/}{};
      print lc($id), "\n";
    }' "$@"
}

unpinned() {
  local resolved="$1" pinned id
  shift
  pinned="$(jq -r '(.pins // .object.pins // [])[]
    | (.identity // ((.location // .repositoryURL // "") | sub("/+$"; "") | sub("\\.git$"; "") | split("/") | last))
    | ascii_downcase' "$resolved")" || return 1
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ! grep -qxF -- "$id" <<<"$pinned"; then
      echo "packages: $id is not in Package.resolved; run bin/dependencies" >&2
      return 1
    fi
  done < <(package_identities "$@")
}

packages_check() {
  local root="$1" found resolved projects=()
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  for found in "$root"/*.xcodeproj/project.pbxproj "$root"/*/*.xcodeproj/project.pbxproj; do
    [ ! -f "$found" ] || projects+=("$found")
  done
  for found in "$root"/*.xcworkspace "$root"/*.xcodeproj; do
    [ -e "$found" ] || continue
    case "$found" in
      *.xcworkspace) resolved="$found/xcshareddata/swiftpm/Package.resolved" ;;
      *) resolved="$found/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ;;
    esac
    if [ -f "$resolved" ]; then
      [ "${#projects[@]}" -eq 0 ] || unpinned "$resolved" "${projects[@]}" || return 1
      pins_fetched "$resolved" "$root/.build/xcode-packages/workspace-state.json" && return 0
      echo "packages: Swift packages are not fetched at the versions Package.resolved pins; run bin/dependencies" >&2
      return 1
    fi
    if [ "${#projects[@]}" -gt 0 ] && grep -qs XCRemoteSwiftPackageReference "${projects[@]}"; then
      echo "packages: Swift packages are not fetched; run bin/dependencies" >&2
      return 1
    fi
    return 0
  done
  if [ ! -f "$root/Package.resolved" ]; then
    if [ -n "$(package_identities "$root/Package.swift" 2>/dev/null)" ]; then
      echo "packages: Package.swift names remote packages but Package.resolved is missing; run bin/dependencies" >&2
      return 1
    fi
    return 0
  fi
  unpinned "$root/Package.resolved" "$root/Package.swift" || return 1
  if ! pins_fetched "$root/Package.resolved" "$root/.build/workspace-state.json"; then
    echo "packages: Swift packages are not fetched at the versions Package.resolved pins; run bin/dependencies" >&2
    return 1
  fi
}
