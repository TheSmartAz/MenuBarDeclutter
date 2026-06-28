# Progress: Phase 6

Status: implemented.

## Tech Stack

- Swift 6 with app declarations isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit for a floating non-activating `NSPanel`.
- SwiftUI for the Second Bar surface and Settings section.
- Swift Testing for pure positioning logic.

## Added

- `SecondBar/SecondBarWindowController.swift`: floating `NSPanel` controller for the Second Bar. It is borderless, can join all Spaces, does not activate the app unnecessarily, closes with Escape, and updates diagnostics when shown/hidden.
- `SecondBar/SecondBarRootView.swift`: SwiftUI Second Bar surface with requirement states, keyboard navigation, hidden/always-hidden item sections, refresh, selection, and move context actions.
- `SecondBar/SecondBarItemView.swift`: app-icon based row/tile rendering using `NSRunningApplication` or bundle icons. No pixel capture or Screen Recording.
- `SecondBar/SecondBarPositioningService.swift`: screen selection and panel placement for below-menu-bar, near-mouse, and last-position modes. Keeps the panel inside visible frames and models notch avoidance.
- `SecondBar/SecondBarViewModel.swift`: pure item filtering, search, sorting, and keyboard selection state.
- `Settings/SecondBarSettingsView.swift`: settings for enablement, item sources, auto-close, placement mode, icon size, labels, outside-click close, and optional owning-app activation.
- `MenuBar-ManagerTests/SecondBarPositioningServiceTests.swift`: coverage for visible-frame clamping, below-menu placement, fallback screens, and modeled notch avoidance.

## Modified

- `App/AppEnvironment.swift`: owns the Second Bar controller/positioning service, wires status menu commands, refreshes the AX index before showing the bar, reveals/highlights selected items through existing `MenuItemActivator`, and syncs settings changes.
- `StatusBar/StatusBarMenuBuilder.swift`: added "Show Second Bar", "Hide Second Bar", and "Toggle Second Bar".
- `Settings/SettingsRootView.swift` and `Settings/SettingsWindowController.swift`: added the Second Bar settings section and callback plumbing.
- `Core/SettingsStore.swift`: added Phase 6 Second Bar settings, defaults, restore-default handling, and clamping for icon size.
- `Core/LiveDiagnosticsStatus.swift`: added Second Bar visibility, item count, current screen, last position, and last selected item.
- `Settings/DiagnosticsSettingsView.swift`: surfaces live Second Bar diagnostics.
- `Core/DiagnosticsExporter.swift`: includes Second Bar settings in privacy-safe diagnostics exports.
- `docs/architecture/architecture-overview.md`, `docs/project-summary.md`, and `docs/testing/manual-qa.md`: updated for Phase 6.

## Privacy And Permissions

- Second Bar is a Pro surface because it depends on the Accessibility discovery index.
- It does not request Screen Recording, use ScreenCaptureKit, sample pixels, or capture real menu bar icon images.
- The user sees app/bundle icons and AX metadata, not screenshots.
- Basic Mode remains fully usable when Pro Mode is disabled or Accessibility permission is missing.

## Verification

- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - Passing Phase 6 tests include:
    - `SecondBarPositioningServiceTests/panelStaysWithinVisibleScreenBounds()`
    - `SecondBarPositioningServiceTests/belowMenuBarPositionsPanelUnderVisibleFrameTop()`
    - `SecondBarPositioningServiceTests/fallsBackWhenScreensAreMissing()`
    - `SecondBarPositioningServiceTests/notchAvoidanceMovesPanelOutOfModeledNotch()`

## Notes

- The Second Bar intentionally does not click original menu bar items. Selection reveals/highlights the original item and leaves the final click to the user.
- The project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files under `MenuBar-Manager/` and test files under `MenuBar-ManagerTests/` are picked up by the existing targets.
