# Second Bar

Second Bar is a private-access floating panel for hidden and always-hidden menu bar items. It opens by default, uses Accessibility metadata when macOS permission is granted, and can use Accurate Icons rendered thumbnails when that separate opt-in capture path is enabled.

## What It Does

- Opens a floating, non-activating AppKit `NSPanel`.
- Displays hidden and always-hidden items from the local Accessibility snapshot.
- Shows rendered thumbnails or app fallback icons, app names, optional item titles, and zone badges.
- Provides a search field for hidden items.
- Supports keyboard navigation and Escape close.
- Supports placement below the menu bar, near the mouse, or at the last position.
- Keeps the panel within visible screen frames, models notch avoidance, and repositions after display, active Space, and screen wake changes.
- Can auto-close after selection or close when clicking outside.
- Can optionally bring the owning app to front after selection.
- Uses shared Command Center routing for reveal, highlight, Find Icon, open owning app, group, and assisted-move gate actions.

## User Flow

1. Open Settings -> Find & Rescue.
2. Use Show Second Bar, or open its detailed settings from the Second Bar card.
3. Grant macOS Accessibility permission if hidden-item metadata is not already available.
4. Hide items with the Basic Mode separator.
5. Open Second Bar from the status menu.
6. Search or navigate to an item.
7. Select an item to reveal/highlight the original menu bar item, then click manually.
8. Use the item context menu for Find Icon, favorites, groups, and gated assisted-move dry runs.

## Privacy And Permissions

Second Bar requires the Pro Accessibility discovery index. It does not request Screen Recording on its own, automate clicks, use private APIs, or use the network. When Accurate Icons is enabled from Privacy settings, shared local rendered thumbnails can replace app-icon fallbacks.

## Implementation

- `MenuBar-Manager/SecondBar/SecondBarRootView.swift`
- `MenuBar-Manager/SecondBar/SecondBarWindowController.swift`
- `MenuBar-Manager/SecondBar/SecondBarViewModel.swift`
- `MenuBar-Manager/SecondBar/SecondBarItemActionPlanner.swift`
- `MenuBar-Manager/SecondBar/SecondBarItemView.swift`
- `MenuBar-Manager/SecondBar/SecondBarPositioningService.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`

## Verification

- `MenuBar-ManagerTests/SecondBarViewModelTests.swift`
- `MenuBar-ManagerTests/SecondBarPositioningServiceTests.swift`
- UI tests for requirement states
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Second Bar is not a pixel-perfect captured duplicate of the real menu bar. Accurate Icons improves individual icon thumbnails when the item is capturable, but offscreen/overflow items can still use stale or fallback images.
- Some menu bar items may lack useful Accessibility labels or ownership metadata.
- Display, notch, Spaces, and sleep/wake behavior require hands-on QA.
- Experimental move attempts remain explicitly gated and are not broad automated clicking.
