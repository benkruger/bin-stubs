# iOS Standards

The iOS app is held by swift-format and its tests at full strength.

## The Rule

- swift-format formats and lints `Sources` and `Tests`.
- The tests cover 100% of the source lines, through `xcodebuild` for a
  project or workspace and `swift test` for a Swift package.
- No swift-format or SwiftLint rule is silenced in code
  (`no-lint-exceptions.md`).
- `.xcode-version` pins Xcode; `bin/ci` fails unless that Xcode is selected.
