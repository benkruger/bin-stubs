# iOS Standards

The iOS app is held by swift-format and its tests at full strength.

## The Rule

- `bin/format` rewrites `Sources` and `Tests` with swift-format, and
  `bin/lint` fails on any swift-format finding there; every finding is
  fixed in the code (`no-lint-exceptions.md`). Trigger: any edit under
  `Sources` or `Tests`.
- A Swift package builds and tests with `-warnings-as-errors`. An Xcode
  workspace or project, used first when one sits in the folder, builds
  and tests with `xcodebuild` on `IOS_DESTINATION` or else the first iOS
  Simulator or Mac it lists, and `bin/build` fails any of its own targets
  that does not set `SWIFT_TREAT_WARNINGS_AS_ERRORS` and
  `GCC_TREAT_WARNINGS_AS_ERRORS` to YES, so a compiler warning in the
  app's own code fails every build and test. Trigger: any source, project
  or `Package.swift` change.
- `bin/test` fails below 100% line coverage of the sources. Trigger: any
  source or test change.
- `bin/dependencies` updates every package to the newest version its
  requirement allows: `swift package update` for a Swift package, and for
  an Xcode workspace or project it drops the resolved versions and
  runs `xcodebuild -resolvePackageDependencies`. It fails unless every
  package resolves, and every other script fails with "run
  bin/dependencies" when a project's packages are not fetched or a Swift
  package's packages are not fetched or are older than its
  `Package.resolved`. Trigger: a dependency bump.
- `bin/changed` runs `bin/format`, `bin/lint` and `bin/test` when the
  folder has changed or untracked files, and exits green when it has none.
  Trigger: every edit.
- `.xcode-version` pins Xcode; outside CI, `bin/ci` fails unless that
  Xcode is selected. Trigger: an Xcode upgrade.
<!-- audited: 04bf698236f5 -->
