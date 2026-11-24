#!/usr/bin/env bash

xcode_dependency() {
  local dir="$1"
  mkdir -p "$dir/Sources/Dep"
  cat >"$dir/Package.swift" <<'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Dep",
  products: [.library(name: "Dep", targets: ["Dep"])],
  targets: [.target(name: "Dep")]
)
EOF
  cat >"$dir/Sources/Dep/Dep.swift" <<'EOF'
public func dep() -> Int {
  var unused = 1
  return 0
}
EOF
  git -C "$dir" init -q -b main
  git -C "$dir" add -A
  git -C "$dir" -c user.email=dep@example.com -c user.name=dep commit -q -m dep
  git -C "$dir" tag 1.0.0
  printf 'file://%s\n' "$dir"
}

swift_dependency() {
  local dir="$1"
  mkdir -p "$dir/Sources/Dep"
  printf '%s\n' '// swift-tools-version: 6.0' 'import PackageDescription' '' 'let package = Package(' \
    '  name: "Dep",' '  products: [.library(name: "Dep", targets: ["Dep"])],' '  targets: [.target(name: "Dep")]' \
    ')' >"$dir/Package.swift"
  printf 'public func dep() -> Int { 0 }\n' >"$dir/Sources/Dep/Dep.swift"
  git -C "$dir" init -q -b main
  git -C "$dir" add -A
  git -C "$dir" -c user.email=dep@example.com -c user.name=dep commit -q -m dep
  git -C "$dir" tag 1.0.0
}

seed_xcode() {
  local app="$1" dep_url="$2" project="$1/App.xcodeproj"
  mkdir -p "$app/Sources/App" "$app/Tests/AppTests" "$project/xcshareddata/xcschemes"
  xcodebuild -version | awk 'NR == 1 { print $2 }' >"$app/.xcode-version"
  cat >"$app/Sources/App/Add.swift" <<'EOF'
import Dep

public func add(_ a: Int, _ b: Int) -> Int { a+b+dep() }
EOF
  cat >"$app/Tests/AppTests/AddTests.swift" <<'EOF'
import Testing
@testable import App

@Test func adds() {
    #expect(add(1, 2) == 3)
}
EOF
  cat >"$project/project.pbxproj" <<'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {
		0A0000000000000000000001 = {isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600; }; buildConfigurationList = 0A0000000000000000000016; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, ); mainGroup = 0A0000000000000000000002; minimizedProjectReferenceProxies = 1; packageReferences = (0A0000000000000000000011, ); preferredProjectObjectVersion = 77; productRefGroup = 0A0000000000000000000003; projectDirPath = ""; projectRoot = ""; targets = (0A0000000000000000000008, 0A0000000000000000000009, ); };
		0A0000000000000000000002 = {isa = PBXGroup; children = (0A0000000000000000000004, 0A0000000000000000000005, 0A0000000000000000000003, ); sourceTree = "<group>"; };
		0A0000000000000000000003 = {isa = PBXGroup; children = (0A0000000000000000000006, 0A0000000000000000000007, ); name = Products; sourceTree = "<group>"; };
		0A0000000000000000000004 = {isa = PBXFileSystemSynchronizedRootGroup; path = Sources/App; sourceTree = "<group>"; };
		0A0000000000000000000005 = {isa = PBXFileSystemSynchronizedRootGroup; path = Tests/AppTests; sourceTree = "<group>"; };
		0A0000000000000000000006 = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = App.framework; sourceTree = BUILT_PRODUCTS_DIR; };
		0A0000000000000000000007 = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = AppTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		0A0000000000000000000008 = {isa = PBXNativeTarget; buildConfigurationList = 0A0000000000000000000019; buildPhases = (0A000000000000000000000A, 0A000000000000000000000B, ); buildRules = ( ); dependencies = ( ); fileSystemSynchronizedGroups = (0A0000000000000000000004, ); name = App; packageProductDependencies = (0A0000000000000000000012, ); productName = App; productReference = 0A0000000000000000000006; productType = "com.apple.product-type.framework"; };
		0A0000000000000000000009 = {isa = PBXNativeTarget; buildConfigurationList = 0A000000000000000000001C; buildPhases = (0A000000000000000000000C, 0A000000000000000000000D, ); buildRules = ( ); dependencies = (0A000000000000000000000F, ); fileSystemSynchronizedGroups = (0A0000000000000000000005, ); name = AppTests; productName = AppTests; productReference = 0A0000000000000000000007; productType = "com.apple.product-type.bundle.unit-test"; };
		0A000000000000000000000A = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; };
		0A000000000000000000000B = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (0A0000000000000000000013, ); runOnlyForDeploymentPostprocessing = 0; };
		0A000000000000000000000C = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; };
		0A000000000000000000000D = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (0A0000000000000000000010, ); runOnlyForDeploymentPostprocessing = 0; };
		0A000000000000000000000E = {isa = PBXContainerItemProxy; containerPortal = 0A0000000000000000000001; proxyType = 1; remoteGlobalIDString = 0A0000000000000000000008; remoteInfo = App; };
		0A000000000000000000000F = {isa = PBXTargetDependency; target = 0A0000000000000000000008; targetProxy = 0A000000000000000000000E; };
		0A0000000000000000000010 = {isa = PBXBuildFile; fileRef = 0A0000000000000000000006; };
		0A0000000000000000000011 = {isa = XCRemoteSwiftPackageReference; repositoryURL = "DEP_URL"; requirement = {kind = upToNextMajorVersion; minimumVersion = 1.0.0; }; };
		0A0000000000000000000012 = {isa = XCSwiftPackageProductDependency; package = 0A0000000000000000000011; productName = Dep; };
		0A0000000000000000000013 = {isa = PBXBuildFile; productRef = 0A0000000000000000000012; };
		0A0000000000000000000014 = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES; GCC_OPTIMIZATION_LEVEL = 0; MACOSX_DEPLOYMENT_TARGET = 14.0; ONLY_ACTIVE_ARCH = YES; SDKROOT = macosx; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_TREAT_WARNINGS_AS_ERRORS = YES; GCC_TREAT_WARNINGS_AS_ERRORS = YES; SWIFT_VERSION = 6.0; }; name = Debug; };
		0A0000000000000000000015 = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; MACOSX_DEPLOYMENT_TARGET = 14.0; SDKROOT = macosx; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_TREAT_WARNINGS_AS_ERRORS = YES; GCC_TREAT_WARNINGS_AS_ERRORS = YES; SWIFT_VERSION = 6.0; }; name = Release; };
		0A0000000000000000000016 = {isa = XCConfigurationList; buildConfigurations = (0A0000000000000000000014, 0A0000000000000000000015, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
		0A0000000000000000000017 = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_IDENTITY = "-"; DEFINES_MODULE = YES; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = com.example.App; PRODUCT_NAME = "$(TARGET_NAME)"; SKIP_INSTALL = YES; }; name = Debug; };
		0A0000000000000000000018 = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_IDENTITY = "-"; DEFINES_MODULE = YES; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = com.example.App; PRODUCT_NAME = "$(TARGET_NAME)"; SKIP_INSTALL = YES; }; name = Release; };
		0A0000000000000000000019 = {isa = XCConfigurationList; buildConfigurations = (0A0000000000000000000017, 0A0000000000000000000018, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
		0A000000000000000000001A = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_IDENTITY = "-"; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = com.example.AppTests; PRODUCT_NAME = "$(TARGET_NAME)"; }; name = Debug; };
		0A000000000000000000001B = {isa = XCBuildConfiguration; buildSettings = {CODE_SIGN_IDENTITY = "-"; GENERATE_INFOPLIST_FILE = YES; PRODUCT_BUNDLE_IDENTIFIER = com.example.AppTests; PRODUCT_NAME = "$(TARGET_NAME)"; }; name = Release; };
		0A000000000000000000001C = {isa = XCConfigurationList; buildConfigurations = (0A000000000000000000001A, 0A000000000000000000001B, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
	};
	rootObject = 0A0000000000000000000001;
}
EOF
  DEP_URL="$dep_url" perl -pi -e 's/DEP_URL/$ENV{DEP_URL}/' "$project/project.pbxproj"
  cat >"$project/xcshareddata/xcschemes/App.xcscheme" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "0A0000000000000000000008" BuildableName = "App.framework" BlueprintName = "App" ReferencedContainer = "container:App.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "0A0000000000000000000009" BuildableName = "AppTests.xctest" BlueprintName = "AppTests" ReferencedContainer = "container:App.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
   </LaunchAction>
</Scheme>
EOF
}
