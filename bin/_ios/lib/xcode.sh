#!/usr/bin/env bash

xcode_container() {
  local found
  for found in *.xcworkspace *.xcodeproj; do
    [ -e "$found" ] || continue
    case "$found" in
      *.xcworkspace) XCODE_ARGS=(-workspace "$found") ;;
      *) XCODE_ARGS=(-project "$found") ;;
    esac
    XCODE_ARGS+=(-scheme "${found%.*}" -clonedSourcePackagesDirPath "$PWD/.build/xcode-packages")
    return 0
  done
  return 1
}

xcode_destination() {
  local destination
  if [ -n "${IOS_DESTINATION:-}" ]; then
    printf '%s\n' "$IOS_DESTINATION"
    return 0
  fi
  destination="$(xcodebuild -showdestinations "${XCODE_ARGS[@]}" -disableAutomaticPackageResolution -derivedDataPath "$PWD/.build/xcode-build" 2>/dev/null |
    awk '/Ineligible destinations/ { exit }
      match($0, /\{ platform:(iOS Simulator|macOS), (arch:[^,]+, )?id:[0-9A-F-]+,/) {
        found = substr($0, RSTART, RLENGTH)
        arch = ""
        if (match(found, /arch:[^,]+/)) arch = ",arch=" substr(found, RSTART + 5, RLENGTH - 5)
        sub(/.*id:/, "", found)
        sub(/,$/, "", found)
        print "id=" found arch
        exit
      }')"
  if [ -z "$destination" ]; then
    echo "xcodebuild lists no iOS Simulator or Mac to run ${XCODE_ARGS[3]} on; set IOS_DESTINATION" >&2
    return 1
  fi
  printf '%s\n' "$destination"
}

xcode_loose_targets() {
  xcodebuild -showBuildSettings -json "${XCODE_ARGS[@]}" -disableAutomaticPackageResolution \
    -derivedDataPath "$PWD/.build/xcode-build" build-for-testing |
    jq -r '.[] | select(.buildSettings.PROJECT_FILE_PATH | test("/(Pods|\\.build|SourcePackages)/") | not)
      | select(.buildSettings.SWIFT_TREAT_WARNINGS_AS_ERRORS != "YES" or .buildSettings.GCC_TREAT_WARNINGS_AS_ERRORS != "YES")
      | .target'
}
