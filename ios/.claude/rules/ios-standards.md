# iOS Standards

The iOS app is held by swift-format and its tests at full strength.

## The Rule

- `bin/format` rewrites with swift-format every tracked or
  unignored untracked Swift file in the app, bar symlinks and files under
  `.build` or `.flow-states`, and `bin/lint` fails on any swift-format
  finding in them; every finding is fixed in the code
  (`no-lint-exceptions.md`). Trigger: any edit to a Swift file.
- A Swift package builds and tests with `-warnings-as-errors` and
  `--disable-automatic-resolution`, so it uses only the versions
  `Package.resolved` names and fetches nothing. An Xcode
  workspace or project, used first when one sits in the folder, builds
  and tests with `xcodebuild` on `IOS_DESTINATION` or else the first iOS
  Simulator or Mac it lists, and `bin/build` fails any of its own targets
  that does not set `SWIFT_TREAT_WARNINGS_AS_ERRORS` and
  `GCC_TREAT_WARNINGS_AS_ERRORS` to YES, so a compiler warning in the
  app's own code fails every build and test. Trigger: any source, project
  or `Package.swift` change.
- `bin/test` fails below 100% line coverage of the sources: every Swift
  file in the app's folder that coverage reports, bar `Tests/`, `.build/`
  and `.xctest` targets. Trigger: any source or test change.
- `bin/dependencies` updates every package to the newest version its
  requirement allows: `swift package update` for a Swift package, and for
  an Xcode workspace or project it drops the resolved versions and
  runs `xcodebuild -resolvePackageDependencies`. It fails unless every
  package resolves, and every other script fails with "run
  bin/dependencies" when a project's packages are not fetched, a Swift
  package's checkouts in `.build/workspace-state.json` are not at the
  revisions its `Package.resolved` pins, or its `Package.swift` names a
  `.package(url:` and it has no `Package.resolved`. Trigger: a dependency
  bump.
- `bin/changed` runs `bin/format`, `bin/lint` and `bin/test` when the
  folder has changed or untracked files, and exits green when it has none.
  Trigger: every edit.
- `.xcode-version` pins Xcode; outside CI, `bin/ci` fails unless that
  Xcode is selected. Trigger: an Xcode upgrade.
<!-- audited: a0bdb25215c3 -->
