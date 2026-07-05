# New Item Inbox v0.1.1

Status: Preview.

New Item Inbox helps users notice newly discovered menu bar items before they get lost in a hidden area.

## Intended Flow

When Pro Discovery sees an item that has not been reviewed before, the user can choose to:

- keep it visible
- move it to hidden with manual instructions
- move it to always hidden with manual instructions
- add it to a collection or tag
- show it in Find Icon
- show it in Second Bar
- dismiss it

Assisted Move may be offered only as Experimental and only after all gates pass.

## Privacy Model

The inbox stores hashed item keys for known and dismissed items. Raw titles, bundle IDs, and live item identities must not appear in diagnostics by default.

## Current Scope

Phase 14 adds:

- `NewMenuBarItem`
- `NewMenuBarItemInbox`
- `NewMenuBarItemInboxDetector`
- `NewMenuBarItemInboxStore`
- detection, dismiss, reset, and persistence logic
- live Pro Discovery scan integration through `MenuBarScanCoordinator`
- local persistence at `new-menu-bar-item-inbox.json` under Application Support
- Find & Rescue count/display plumbing
- a dedicated Find & Rescue review list with privacy-safe generic item labels
- user-facing dismiss and reset controls
- a conditional status-menu `Open New Items...` row when review items exist and Pro Discovery gates are satisfied
- unit tests for detection, known item suppression, dismissal, reset, scan suppression, review-state privacy, live scan count updates, and status-menu visibility

v0.1.3 adds stable hashed review identities, placement preference actions, Find Icon / Second Bar / collection / Arrange handoffs, and aggregate redacted diagnostics. See `docs/features/new-item-inbox-v0.1.3.md`.
