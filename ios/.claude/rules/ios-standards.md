# iOS Standards

The iOS app is held by swift-format and its tests at full strength.

## The Rule

- `bin/format` rewrites `Sources` and `Tests` with swift-format, and
  `bin/lint` fails on any swift-format finding there.
- `bin/test` fails below 100% line coverage of the sources, run through
  `xcodebuild` for a project or workspace and `swift test` for a Swift
  package.
- Every swift-format and SwiftLint rule runs on all code
  (`no-lint-exceptions.md`).
- `.xcode-version` pins Xcode; `bin/ci` fails unless that Xcode is selected.
- Trigger: any change to an iOS `bin/` script.
<!-- audited: 7435f81ac03e -->
