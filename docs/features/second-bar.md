# Second Bar

Second Bar is an optional Pro floating panel for hidden and always-hidden menu bar items. It uses Accessibility metadata and app/bundle icons, not captured menu bar pixels.

## What It Does

- Opens a floating, non-activating AppKit `NSPanel`.
- Displays hidden and always-hidden items from the local Accessibility snapshot.
- Shows app icons, app names, optional item titles, and zone badges.
- Provides a search field for hidden items.
- Supports keyboard navigation and Escape close.
- Supports placement below the menu bar, near the mouse, or at the last position.
- Keeps the panel within visible screen frames and models notch avoidance.
- Can auto-close after selection or close when clicking outside.
- Can optionally bring the owning app to front after selection.
- Uses the same non-clicking reveal/highlight path as Find Icon.

## User Flow

1. Enable Second Bar in Settings -> Second Bar.
2. Enable Pro Mode, Accessibility Discovery, and Accessibility permission if not already configured.
3. Hide items with the Basic Mode separator.
4. Open Second Bar from the status menu.
5. Search or navigate to an item.
6. Select an item to reveal/highlight the original menu bar item, then click manually.

## Privacy And Permissions

Second Bar requires the Pro Accessibility discovery index. It uses item metadata and app/bundle icons only. It does not request Screen Recording, use ScreenCaptureKit, sample pixels, automate clicks, use private APIs, or use the network.

## Implementation

- `MenuBar-Manager/SecondBar/SecondBarRootView.swift`
- `MenuBar-Manager/SecondBar/SecondBarWindowController.swift`
- `MenuBar-Manager/SecondBar/SecondBarViewModel.swift`
- `MenuBar-Manager/SecondBar/SecondBarItemView.swift`
- `MenuBar-Manager/SecondBar/SecondBarPositioningService.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`

## Verification

- `MenuBar-ManagerTests/SecondBarViewModelTests.swift`
- `MenuBar-ManagerTests/SecondBarPositioningServiceTests.swift`
- UI tests for requirement states
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Second Bar is not a pixel-perfect captured duplicate of the real menu bar.
- Some menu bar items may lack useful Accessibility labels or ownership metadata.
- Display, notch, Spaces, and sleep/wake behavior require hands-on QA.
