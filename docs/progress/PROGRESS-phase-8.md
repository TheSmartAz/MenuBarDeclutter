# Progress: Phase 8

Status: implemented.

## Tech Stack

- Swift 6 with app declarations isolated to `MainActor`.
- Native macOS 26.0+.
- SwiftUI for Profiles and Smart Triggers settings.
- JSON persistence in Application Support.
- AppKit `NSAppleEventManager` URL event handling for lightweight automation.
- Swift Testing for profile storage, profile dry-run behavior, and trigger evaluation.

## Added

- `Profiles/ProfileModel.swift`: Codable profile model with visibility, Second Bar, auto-rehide, hover reveal, bundle-to-zone targets, and notes.
- `Profiles/ProfileStore.swift`: Application Support JSON profile storage with load, save, create, duplicate, delete, import, export, encode, and decode support.
- `Profiles/ProfileApplicationService.swift`: dry-run summaries and conservative profile application. Basic settings apply immediately; zone moves are reported but not silently executed.
- `Profiles/ProfileEditorView.swift`: profile editor for visibility/behavior settings and bundle-id target zones.
- `Profiles/ProfileListView.swift`: Settings UI for listing, creating, duplicating, deleting, editing, applying, dry-running, importing, and exporting profiles. Includes the initial Smart Triggers UI.
- `Profiles/TriggerModel.swift`: Codable trigger model and evaluation context for external displays, launched/frontmost apps, battery low, time of day, focus placeholder, and Wi-Fi SSID.
- `Profiles/TriggerRuleEvaluator.swift`: pure trigger matching and debounce logic.
- `Profiles/TriggerService.swift`: trigger persistence plus safe runtime observers for display changes, app launch, frontmost app changes, and minute-based evaluation.
- `Profiles/AutomationURLHandler.swift`: minimal URL automation commands for expand, collapse, reveal-all, show second bar, and apply profile by name.
- `Config/MenuBarDeclutter-Info.plist`: explicit app Info.plist registering the `menubardeclutter://` URL scheme.
- `docs/automation-roadmap.md`: scope and future direction for AppleScript/Shortcuts automation.
- `MenuBar-ManagerTests/ProfileStoreTests.swift`: profile JSON save/load and import/export coverage.
- `MenuBar-ManagerTests/ProfileApplicationDryRunTests.swift`: dry-run permission/move warnings and conservative apply behavior.
- `MenuBar-ManagerTests/TriggerRuleEvaluatorTests.swift`: trigger matching and debounce coverage.

## Modified

- `App/AppEnvironment.swift`: owns the profile store, profile application service, trigger service, and automation URL handler. Loads profiles/triggers on startup and starts/stops triggers with settings.
- `Settings/SettingsRootView.swift` and `Settings/SettingsWindowController.swift`: added the Profiles settings section and callbacks.
- `Core/SettingsStore.swift`: added `smartTriggersEnabled`, defaults, and restore-default handling.
- `Core/LiveDiagnosticsStatus.swift`: added active profile, last trigger, trigger evaluation log, and profile apply log.
- `Settings/DiagnosticsSettingsView.swift`: surfaces live profile and trigger diagnostics.
- `Core/DiagnosticsExporter.swift`: includes smart trigger enablement in privacy-safe diagnostics exports.
- `Accessibility/MenuBarZone.swift` and `Hiding/HidingVisibilityState.swift`: made profile-relevant values Codable.
- `docs/architecture/architecture-overview.md`, `docs/project-summary.md`, and `docs/testing/manual-qa.md`: updated for Phase 8.

## Privacy And Permissions

- Profiles are local JSON files under Application Support.
- Trigger evaluation uses local public system state. Current runtime observers cover display count, running/frontmost bundle identifiers, time, and battery percentage when public power-source APIs expose it. Focus and Wi-Fi rules are modeled for future safe providers and only match when context supplies those values.
- Applying a profile never silently performs bulk CGEvent icon moves.
- Smart triggers apply only conservative Basic settings and visibility state; Pro zone targets appear in dry-run summaries and require explicit user action outside normal trigger evaluation.
- URL automation is local and command-limited. It does not add network access or background telemetry.

## Verification

- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build`
  - Final result: `BUILD SUCCEEDED`.
  - Verified the built app `Info.plist` contains `CFBundleURLTypes` for `menubardeclutter`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - Passing Phase 8 tests include:
    - `ProfileStoreTests/profileSaveLoadRoundTripsJSON()`
    - `ProfileStoreTests/exportAndImportProfileJSON()`
    - `ProfileApplicationDryRunTests/dryRunReportsMovesAndRequirements()`
    - `ProfileApplicationDryRunTests/applyBasicSettingsDoesNotRunZoneMoves()`
    - `TriggerRuleEvaluatorTests/matchesExternalDisplayRule()`
    - `TriggerRuleEvaluatorTests/matchesFrontmostAppRule()`
    - `TriggerRuleEvaluatorTests/matchesBatteryLowRuleOnlyWhenBatteryAvailable()`
    - `TriggerRuleEvaluatorTests/matchesTimeOfDayRule()`
    - `TriggerRuleEvaluatorTests/debouncePreventsRepeatedFire()`

## Notes

- AppleScript dictionary support remains out of scope for Phase 8; URL automation is the implemented lightweight path.
- Initial trigger creation UI includes safe convenience actions for display and Finder/frontmost examples. The underlying evaluator is broader and ready for richer UI/provider work in later phases.
