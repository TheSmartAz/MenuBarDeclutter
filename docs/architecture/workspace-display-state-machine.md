# Workspace Display State Machine

`WorkspaceDisplayCoordinator` coordinates Function Bar and Info Strip preview display.

States include closed, Function Bar visible, Info Strip visible, pinned Function Bar, suspended by Safe Mode, and unavailable states.

Rules:

- Showing Function Bar hides Info Strip.
- Showing Info Strip hides Function Bar.
- Safe Mode suppresses both runtime panels.
- Idle-to-Info Strip starts only when global Info Strip auto-show is enabled and the active Workspace enables Info Strip.
- Hover-to-Function Bar requires the global hover setting and the active Workspace hover behavior to allow it.

The state machine controls app-owned panels only. It does not move real menu bar icons or apply physical profiles.
