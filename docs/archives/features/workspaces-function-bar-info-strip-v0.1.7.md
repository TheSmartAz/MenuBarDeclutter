# Workspaces, Function Bar, Set Builder, and Info Strip v0.1.7

MenuBarDeclutter v0.1.4 through v0.1.7 adds a local-only preview track for app-owned workspace sets and companion panels.

## Privacy Boundary

- Workspaces are stored under Application Support in `Workspaces/workspaces.json`.
- Preview panels are app-owned SwiftUI/AppKit UI.
- Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, or private APIs.
- Menu bar item proxy actions remain gated behind existing Pro Mode and Accessibility Discovery checks.

## v0.1.4 Workspaces Foundation

- Adds default Workspace models: Default, Focus, and Meeting.
- Adds validation, safe repair, local JSON persistence, and backups.
- Adds Command Center workspace targets and switching.
- Adds a hidden Workspaces Preview settings page reachable from Advanced.

## v0.1.5 Function Bar Preview

- Adds an app-owned Function Bar `NSPanel`.
- Adds Set Switcher support and Command Center-routed actions.
- Adds optional primary-click routing to Function Bar, disabled by default.
- Avoids screen capture, pixel inspection, and private APIs.

## v0.1.6 Set Builder

- Adds draft-based editing for create, rename, duplicate, archive, switch, add, remove, reorder, commit, and revert.
- Supports commands, app-owned menu bar item references, linked/detached group references, spacers, dividers, and Info Strip tile selections.
- Protected names remain redacted in diagnostics.

## v0.1.7 Info Strip MVP

- Adds an app-owned Info Strip preview panel.
- Adds local-only tiles: current workspace, clock, hidden count, new item count, recovery warning, and stale scan.
- Pro-derived tiles degrade when Pro Discovery is unavailable.
- Adds rotation and hover-to-Function-Bar preview settings.
