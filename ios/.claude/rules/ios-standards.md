# iOS Standards

The iOS app is held by swift-format and its tests at full strength.

## The Rule

- `bin/format` rewrites `Sources` and `Tests` with swift-format, and
  `bin/lint` fails on any swift-format finding there; every finding is
  fixed in the code (`no-lint-exceptions.md`). Trigger: any edit under
  `Sources` or `Tests`.
- `bin/build` fails unless `swift build` compiles the package with no
  warning. Trigger: any source or `Package.swift` change.
- `bin/test` fails below 100% line coverage of the sources, run through
  `xcodebuild` for a project or workspace and `swift test` for a Swift
  package, where a compiler warning also fails it. Trigger: any source or
  test change.
- `bin/dependencies` runs `swift package update` and fails unless every
  package resolves. Trigger: a dependency bump.
- `bin/changed` runs `bin/format`, `bin/lint` and `bin/test` when the
  folder has changed or untracked files, and exits green when it has none.
  Trigger: every edit.
- `.xcode-version` pins Xcode; outside CI, `bin/ci` fails unless that
  Xcode is selected. Trigger: an Xcode upgrade.
<!-- audited: b27e0ea434e2 -->
