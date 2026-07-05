# Progress: Phase 9

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 9. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 with app/runtime code isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit `NSStatusItem` for Basic menu bar control.
- SwiftUI Diagnostics UI for health and repair actions.
- Swift Testing for health, recovery, and Safe Mode logic.

## Added

- `Health/HealthIssue.swift`: health severity, issue, and recovery-action models.
- `Health/HealthReport.swift`: status derivation and text export for standalone health reports.
- `Health/HealthService.swift`: pure health checks for status item presence, separator lengths, screen geometry, settings integrity, hotkey drift, auto-rehide/hover state, Pro permission state, repeated AX failures, and stale AX scans.
- `Health/RecoveryService.swift`: action dispatcher for automatic repair paths, including targeted settings repairs before falling back to full defaults.
- `Health/SafeModeService.swift`: Option-key launch detection, one-shot Safe Mode flag, crash marker write/clear, and previous-crash detection.
- `MenuBar-ManagerTests/HealthServiceTests.swift`: missing separator, corrupted setting, targeted settings recovery action, and stale AX scan coverage.
- `MenuBar-ManagerTests/RecoveryServiceTests.swift`: separator reset recovery, targeted settings repair, and Pro failure disablement coverage.
- `MenuBar-ManagerTests/SafeModeServiceTests.swift`: crash marker, one-shot flag, clean termination, and Option launch coverage.

## Modified

- `App/AppEnvironment.swift`: added recovery-first startup, crash marker lifecycle, Safe Mode runtime suppression, health report generation, automatic recovery, wake/display/active-Space recovery, and Diagnostics callbacks.
- `StatusBar/StatusBarController.swift`: added status item inspection, required status item recreation, current-state reapply, and runtime suppression hooks for auto-rehide and hover reveal.
- `Core/LiveDiagnosticsStatus.swift`: added latest health report and Safe Mode state.
- `Settings/SettingsWindowController.swift`, `Settings/SettingsRootView.swift`, and `Settings/DiagnosticsSettingsView.swift`: added Health status, issue list, Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch.
- `docs/architecture/architecture-overview.md`, `docs/project-summary.md`, `docs/testing/manual-qa.md`, and `docs/testing/macos26-test-matrix.md`: updated for Phase 9.

## Startup And Recovery

- Launch always starts expanded until status items have been installed and health has passed.
- Collapsed launch preferences are honored only after health is OK.
- A leftover `running.marker` from an unclean exit triggers Safe Mode and expanded/reveal-all startup.
- Safe Mode suppresses auto-rehide, hover reveal, Pro AX scans, icon moving, global hotkeys, Find Icon hotkey, and smart triggers while preserving Basic Mode control.
- Wake/display recovery cancels pending auto-rehide, reapplies geometry/state, refreshes Second Bar placement, optionally rescans AX, and logs a health report.
- Screen/wake/Space recovery is centralized in `AppEnvironment`; Second Bar and Pro scanning react through that recovery path instead of registering duplicate screen-parameter observers.
- Manual Fix Automatically uses the recovery action attached to each issue. It recreates missing status items, resets separator lengths, clears stuck runtime timers, resets corrupted scan interval / Second Bar position / Accessibility status cache individually, and disables Pro Mode only for Pro-dependent failures. Full settings reset remains a fallback, not the default response to every settings issue.

## Privacy And Permissions

- Basic Mode remains fully usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Health checks call the existing Accessibility permission status refresh without prompting.
- Safe Mode and crash markers are local Application Support files.
- Health reports contain status, issue codes/details, and suggested recovery actions; they do not include screenshots, screen contents, network data, or personal file paths.

## Verification

- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build`
  - Final result: `BUILD SUCCEEDED`.
  - Xcode emitted the existing duplicate matching macOS destinations warning.
  - Audit follow-up: the explicit app plist was moved to `Config/MenuBarDeclutter-Info.plist`; the copied-`Info.plist` warning no longer appears.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - New Phase 9 tests passed:
    - `HealthServiceTests/missingSeparatorDetected()`
    - `HealthServiceTests/corruptedSettingDetected()`
    - `HealthServiceTests/settingsIssuesUseTargetedRecoveryActions()`
    - `HealthServiceTests/staleAXScanDetectedWhenProModeEnabled()`
    - `RecoveryServiceTests/recoveryResetsLengths()`
    - `RecoveryServiceTests/targetedSettingsRecoveryDoesNotResetAllSettings()`
    - `RecoveryServiceTests/proModeFailureDisablesDependentFeatures()`
    - `SafeModeServiceTests/previousCrashMarkerTriggersSafeBehavior()`
    - `SafeModeServiceTests/safeModeLaunchFlagIsConsumed()`
    - `SafeModeServiceTests/cleanTerminationClearsCrashMarker()`
    - `SafeModeServiceTests/optionModifierTriggersSafeMode()`

## Notes

- Phase 9 does not add new user-facing product features beyond diagnostics and recovery.
- No ScreenCaptureKit, Screen Recording, network access, private APIs, or source-available/GPL code is introduced.
