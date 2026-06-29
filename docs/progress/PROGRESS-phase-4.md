# Progress: Phase 4

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 4. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 with app declarations isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit for `NSStatusItem`, separator frame discovery, `NSWorkspace`, and System Settings deep-link opening.
- SwiftUI for the Privacy and Diagnostics Settings surfaces.
- ApplicationServices Accessibility APIs for optional, read-only Pro discovery:
  - `AXIsProcessTrustedWithOptions`
  - `AXUIElementCreateSystemWide`
  - `AXUIElementCopyAttributeValue`
  - `AXUIElementGetPid`
- Swift Testing for pure-logic unit coverage.

## Added

- `Permissions/AccessibilityPermissionService.swift`: maps Accessibility trust into `notRequested`, `denied`, `granted`, or `unknown`; checks without prompting by default; requests the system prompt only from an explicit user action; opens the Accessibility privacy pane; logs status transitions; persists the last mapped status in `SettingsStore`.
- `Accessibility/MenuBarZone.swift`: zone model plus pure frame-based classification against primary and always-hidden separator frames.
- `Accessibility/MenuBarItemSnapshot.swift`: read-only scanned item model with deterministic stable ID generation, ownership metadata, frame, zone, system-item heuristic, and scan timestamp.
- `Accessibility/MenuBarScanResult.swift`: scan result wrapper with zone counts, AX failure count, and dedup/merge helpers.
- `Accessibility/AXElementReader.swift`: defensive wrapper around AX attribute reads. Reads only safe attributes, returns optional/result-style values, logs failures, and increments a failure count.
- `Accessibility/AXMenuBarScanner.swift`: read-only scanner that starts from system-wide, app menu bar, and SystemUIServer menu-extra roots where available. It walks bounded depth/element counts and never clicks, drags, activates, records, or moves anything.
- `Accessibility/MenuBarScanCoordinator.swift`: gates scans behind Pro Mode, Accessibility Discovery, and granted permission. Triggers scans on launch, screen changes, visibility changes, and manual refresh; throttles automatic scans via `menuBarScanIntervalSeconds`; keeps manual refresh available while Pro discovery is configured so a newly granted permission can be rechecked.
- `MenuBar-ManagerTests/AccessibilityDiscoveryLogicTests.swift`: tests for zone classification, stable IDs, dedup/merge behavior, and permission status mapping.
- `MenuBar-ManagerTests/MenuBarScanCoordinatorTests.swift`: tests manual refresh after stale permission cache changes, revoked-permission clearing, automatic scan throttling, manual throttle bypass, and Pro Mode disabled degradation.
- `docs/progress/PROGRESS-phase-4.md`: this progress log.

## Modified

- `Core/SettingsStore.swift`: added `proModeEnabled`, `accessibilityDiscoveryEnabled`, `lastAccessibilityPermissionStatus`, and `menuBarScanIntervalSeconds` with defaults, persistence, clamping, and restore-defaults reset.
- `App/AppConstants.swift`: added default/min/max scan interval constants.
- `Core/LiveDiagnosticsStatus.swift`: added Pro diagnostics fields for permission status, scanned snapshots, last scan time, zone counts, and AX failure count.
- `StatusBar/SeparatorController.swift`: added `screenFrame` so Pro discovery can classify scanned items against real separator positions.
- `App/AppEnvironment.swift`: owns `AccessibilityPermissionService`, `AXMenuBarScanner`, and `MenuBarScanCoordinator`; starts/stops the coordinator; refreshes Pro scan state when privacy/behavior settings change.
- `Settings/SettingsWindowController.swift` and `Settings/SettingsRootView.swift`: pass Phase 4 services and privacy-change callbacks into SwiftUI.
- `Settings/PrivacySettingsView.swift`: replaced the placeholder Pro section with Enable/Disable Pro Mode, Accessibility Discovery, Request Permission, Open Settings, scan throttle, and clear privacy copy.
- `Settings/DiagnosticsSettingsView.swift`: added Pro diagnostics rows, manual AX scan refresh, and a snapshot table. Manual refresh is enabled from the Pro discovery settings state rather than a cached granted-permission state, allowing the click to re-check permission after the user grants Accessibility in System Settings.
- `Core/DiagnosticsExporter.swift`: includes Phase 4 settings in privacy-safe diagnostics export and keeps optional JSON values serializable with `NSNull`.
- `MenuBar-ManagerTests/SettingsStoreTests.swift`: added Phase 4 defaults, persistence, scan interval clamping, and restore-defaults coverage.
- `docs/architecture/architecture-overview.md`: documented Phase 4 services, UI, privacy boundary, and status.
- `docs/project-summary.md`: added the Phase 4 summary and updated the privacy boundary.
- `docs/testing/manual-qa.md`: added Phase 4 Pro Mode Accessibility manual QA.

## Privacy And Permissions

- Basic Mode remains the default and remains fully usable without Accessibility permission.
- Pro Mode is opt-in and separate from Basic Mode.
- Accessibility Discovery is separately toggleable and disabled by default.
- `AXIsProcessTrustedWithOptions` uses `kAXTrustedCheckOptionPrompt: false` for ordinary checks.
- The Accessibility prompt is requested only when the user clicks "Request Permission".
- Phase 4 does not request Screen Recording, Apple Events, Input Monitoring, or network access.
- Phase 4 does not use ScreenCaptureKit.
- Phase 4 does not simulate clicks, drags, activation, or icon moving.
- Missing, denied, revoked, or unsupported Accessibility state clears Pro scan diagnostics and leaves Basic Mode behavior intact.

## Verification

- `xcodebuild -list`
  - Result: scheme remains `MenuBar-Manager`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - First run result: build failed because the new Swift Testing suite was not marked `@MainActor` in a project with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
  - Fix: marked `AccessibilityDiscoveryLogicTests` as `@MainActor`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - Passing Phase 4 tests include:
    - `SettingsStoreTests/phase4DefaultsAreRegistered()`
    - `SettingsStoreTests/phase4FieldsPersist()`
    - `SettingsStoreTests/invalidMenuBarScanIntervalClamped()`
    - `SettingsStoreTests/restoreDefaultsResetsPhase4()`
    - `AccessibilityDiscoveryLogicTests/zoneClassificationUsesSeparatorFrames()`
    - `AccessibilityDiscoveryLogicTests/zoneClassificationReturnsUnknownForMissingFrames()`
    - `AccessibilityDiscoveryLogicTests/snapshotStableIDIsDeterministic()`
    - `AccessibilityDiscoveryLogicTests/snapshotStableIDChangesForDifferentOwners()`
    - `AccessibilityDiscoveryLogicTests/scanResultDeduplicatesByStableIDKeepingLatestSnapshot()`
    - `AccessibilityDiscoveryLogicTests/scanResultMergeDeduplicatesPreviousAndCurrentSnapshots()`
    - `AccessibilityDiscoveryLogicTests/permissionStatusMappingDoesNotRequireAccessibilityPermission()`
- Phase 4 audit follow-up:
  - Fixed Diagnostics manual refresh so it can re-check a newly granted Accessibility permission even when the cached status is stale.
  - Added coordinator-level tests for manual refresh, revoke clearing, throttling, and Basic Mode degradation.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Audit follow-up result: `TEST SUCCEEDED`.

## Notes

- The project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files added under `MenuBar-Manager/` and `MenuBar-ManagerTests/` are picked up by the app and unit-test targets without manual `project.pbxproj` target membership edits.
- The checkout already shows broad untracked/generated Phase 0-3 files relative to Git's current index; Phase 4 work was added in the existing synchronized source/test directories without reverting unrelated work.
- Out of scope for Phase 4 remains unchanged: no search window, no second bar, no click/activation, no icon moving, no ScreenCaptureKit.
