# Basic Mode Hiding

Basic Mode is the default menu bar decluttering workflow. It hides and reveals menu bar items using public AppKit `NSStatusItem` behavior, not private menu bar APIs.

## What It Does

- Installs a square control status item for MenuBarDeclutter.
- Installs a variable-length primary separator status item.
- Expands, collapses, toggles, and reveals all hidden items.
- Lets the user Command-drag the separator to choose which items should be hidden.
- Persists collapsed/expanded state through `SettingsStore`.
- Recomputes separator length after display changes.
- Offers emergency recovery from the status menu: Reveal All + Reset Separators.
- Shows a first-run drag hint and lets the user show it again from the status menu.

The hiding mechanism is separator-based: when collapsed, the separator grows wide enough to push later menu bar items off the visible menu bar. When expanded, the separator returns to a short length.

## User Flow

1. Launch the app and look for the MenuBarDeclutter menu bar control.
2. Command-drag the separator so the icons to its right are the ones to hide.
3. Click the control item to toggle hidden items.
4. Use the status menu for Expand, Collapse, Toggle, Reveal All, Reset Separator Length, Show Drag Hint, and emergency recovery.

## Privacy And Permissions

Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access. It uses AppKit status items and local settings only.

## Implementation

- `MenuBar-Manager/StatusBar/StatusBarController.swift`
- `MenuBar-Manager/StatusBar/SeparatorController.swift`
- `MenuBar-Manager/StatusBar/StatusItemFactory.swift`
- `MenuBar-Manager/StatusBar/StatusBarMenuBuilder.swift`
- `MenuBar-Manager/Hiding/HidingService.swift`
- `MenuBar-Manager/Hiding/ScreenGeometryService.swift`
- `MenuBar-Manager/Hiding/HidingVisibilityState.swift`

## Verification

- `MenuBar-ManagerTests/HidingServiceTests.swift`
- `MenuBar-ManagerTests/HidingVisibilityStateTests.swift`
- `MenuBar-ManagerTests/ScreenGeometryServiceTests.swift`
- `MenuBar-ManagerTests/StatusBarMenuBuilderTests.swift`
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Hiding is based on public separator layout, not private Apple menu bar APIs.
- Real Command-drag placement, notch displays, external displays, Spaces, and sleep/wake behavior still require hands-on QA.
- Some menu bar items may react differently depending on app ownership and current macOS layout.
