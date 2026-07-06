# Second Bar

Second Bar is a Pro find-and-rescue surface for hidden and always-hidden menu bar items. The current implementation has two related surfaces: a one-line compact strip opened from the MenuBarDeclutter status item, and a larger management panel for search, item state, and actions. Both use local Accessibility metadata, and the compact/status-menu entry point requires Accurate Icons plus Screen Recording so it can behave like a real icon strip instead of a generic fallback list.

## What It Does

- Opens a floating, non-activating AppKit `NSPanel` for the management surface.
- Opens a one-line compact strip from the primary status item when the Pro Second Bar readiness gate passes.
- Displays hidden and always-hidden items from the local Accessibility snapshot.
- Shows rendered thumbnails or app fallback icons, app names, optional item titles, and zone badges in the management panel.
- Shows Hidden-zone Accurate Icons in the compact strip, with overflow represented by `+N`.
- Provides a search field for hidden items.
- Supports keyboard navigation and Escape close.
- Supports placement below the menu bar, near the mouse, or at the last position.
- Keeps the panel within visible screen frames, models notch avoidance, and repositions after display, active Space, and screen wake changes.
- Can auto-close after selection or close when clicking outside.
- Can optionally bring the owning app to front after selection.
- Uses shared Command Center routing for reveal, highlight, Find Icon, open owning app, group, and assisted-move gate actions.

## User Flow

1. Open Settings -> Privacy or Settings -> Second Bar.
2. Complete Pro Second Bar Setup: Optional Pro, Accessibility Discovery, Accessibility permission, Accurate Icons, and Screen Recording.
3. Hide items with the Basic Mode separator.
4. Click the MenuBarDeclutter status item to open the compact strip.
5. Click a prepared third-party icon for optimistic direct activation, or use Manage/Search to open the larger Second Bar panel.
6. Search or navigate to an item in the management panel.
7. Use item actions for reveal, highlight, Find Icon, groups, and gated assisted-move dry runs.

## Privacy And Permissions

Second Bar readiness requires Optional Pro, Accessibility Discovery, Accessibility permission, Accurate Icons enabled, and Screen Recording granted. The Accessibility and Screen Recording prompts must come only from explicit user actions in setup/privacy controls.

Second Bar does not use private APIs, Apple Events, Input Monitoring, network access, telemetry, or offscreen/private menu bar capture. Accurate Icons uses public ScreenCaptureKit visible-region capture for local thumbnails after Screen Recording is granted. Basic Mode remains usable when any Pro Second Bar gate is missing.

## Implementation

- `MenuBar-Manager/SecondBar/SecondBarRootView.swift`
- `MenuBar-Manager/SecondBar/SecondBarWindowController.swift`
- `MenuBar-Manager/SecondBar/SecondBarViewModel.swift`
- `MenuBar-Manager/SecondBar/ProSecondBarReadiness.swift`
- `MenuBar-Manager/SecondBar/SecondBarCompactStripPlanner.swift`
- `MenuBar-Manager/SecondBar/SecondBarCompactStripRootView.swift`
- `MenuBar-Manager/SecondBar/SecondBarCompactStripWindowController.swift`
- `MenuBar-Manager/SecondBar/SecondBarItemActionPlanner.swift`
- `MenuBar-Manager/SecondBar/SecondBarItemView.swift`
- `MenuBar-Manager/SecondBar/SecondBarPositioningService.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`

## Verification

- `MenuBar-ManagerTests/SecondBarViewModelTests.swift`
- `MenuBar-ManagerTests/SecondBarPositioningServiceTests.swift`
- `MenuBar-ManagerTests/ProSecondBarCompactStripTests.swift`
- UI tests for requirement states
- Manual QA: `docs/testing/manual-pro-second-bar-compact-strip-qa.md`

## Known Limitations

- Second Bar is not a pixel-perfect captured duplicate of the real menu bar. Accurate Icons improves individual icon thumbnails when the item is capturable, but offscreen/overflow items can still use stale images or be excluded from the compact strip until prepared.
- Some menu bar items may lack useful Accessibility labels or ownership metadata.
- Display, notch, Spaces, and sleep/wake behavior require hands-on QA.
- Experimental move attempts remain explicitly gated and are not broad automated clicking.
