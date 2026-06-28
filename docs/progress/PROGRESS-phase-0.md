# Progress: Phase 0

Status: implemented.

## Tech Stack

- Swift 6 mode.
- Native macOS 26.0+ target.
- SwiftUI app lifecycle.
- AppKit for `NSApplicationDelegate`, `NSStatusItem`, `NSMenu`, and `NSWindowController`.
- SwiftUI for Settings views.
- Observation framework through `@Observable` and `@Bindable`.
- UserDefaults for Phase 0 settings persistence.
- Swift Testing for unit tests.

## Added

- `App/MenuBarDeclutterApp.swift`: SwiftUI entry point.
- `App/AppDelegate.swift`: AppKit delegate and menu bar activation policy.
- `App/AppConstants.swift`: Product constants and app version helpers.
- `App/AppEnvironment.swift`: Long-lived service ownership and command coordination.
- `StatusBar/StatusBarController.swift`: Temporary menu bar status item.
- `StatusBar/StatusBarMenuBuilder.swift`: Menu construction and command target bridge.
- `Settings/SettingsWindowController.swift`: AppKit settings window hosting SwiftUI.
- `Settings/SettingsRootView.swift`: Settings navigation shell.
- `Settings/GeneralSettingsView.swift`: General settings skeleton.
- `Settings/PrivacySettingsView.swift`: Basic Mode privacy status skeleton.
- `Settings/DiagnosticsSettingsView.swift`: In-memory diagnostics display.
- `Core/SettingsStore.swift`: Typed UserDefaults-backed settings.
- `Core/DiagnosticsLogger.swift`: In-memory ring buffer logger with Debug console printing.
- `Core/AppSupportPaths.swift`: Future Application Support path helper.
- `scripts/build_debug.sh`, `scripts/build_release.sh`, `scripts/test.sh`.
- Architecture, research, license, macOS 26, manual QA, test matrix, release, summary, and progress docs.
- Unit tests for SettingsStore and DiagnosticsLogger.

## Removed

- The stock SwiftData sample app entry point.
- The stock SwiftData `ContentView`.
- The stock SwiftData `Item` model.

## Modified

- `MenuBar-Manager.xcodeproj/project.pbxproj`
  - Set deployment target values to macOS 26.0.
  - Set target Swift versions to Swift 6.0.
  - Added generated Info.plist keys for `CFBundleDisplayName`, `CFBundleName`, and `LSUIElement`.
  - Kept hardened runtime enabled.
  - Kept the existing App Sandbox setting enabled and documented it for release review.
- `AGENTS.md`
  - Added Phase 0 status notes and documentation pointers.

## Privacy And Permissions

- Basic Mode remains the only implemented mode.
- No Accessibility prompt is requested.
- No Screen Recording prompt is requested.
- No Apple Events prompt is requested.
- No Input Monitoring prompt is requested.
- No network feature or dependency was added.

## Verification

- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build`
  - Result: `BUILD SUCCEEDED`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Result: `TEST SUCCEEDED`.
  - Swift Testing unit tests passed:
    - `SettingsStoreTests/defaultValuesAreRegistered()`
    - `SettingsStoreTests/valuesPersistToUserDefaults()`
    - `DiagnosticsLoggerTests/ringBufferRetainsLatestEvents()`
    - `DiagnosticsLoggerTests/capacityIsAtLeastOne()`
  - Existing UI launch tests passed.
- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' -configuration Release build`
  - Result: `BUILD SUCCEEDED`.
- `scripts/build_debug.sh`
  - Result: printed `xcodebuild -scheme MenuBar-Manager -destination platform=macOS -configuration Debug build` and completed with `BUILD SUCCEEDED`.
- Generated Debug app Info.plist:
  - `LSUIElement = true`.
  - `CFBundleDisplayName = MenuBarDeclutter`.
- Generated Release app Info.plist:
  - `LSUIElement = true`.
