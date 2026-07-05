# Find Icon v0.1.1

Status: Stable for local search and reveal/highlight. Advanced actions are Preview or Experimental.

Find Icon uses the optional Pro Accessibility discovery index. It does not use screenshots, pixels, Screen Recording, ScreenCaptureKit, private APIs, network access, telemetry, or automatic clicking.

## Implemented

- Search over locally discovered menu bar item metadata.
- Filters for All, Recent, Favorites, Visible, Hidden, and Always Hidden.
- Keyboard navigation for selection, Return activation, and Escape close.
- Recents/favorites stored as local hashed convenience state.
- Reveal, highlight, show in Second Bar, open owning app, create group from item, and add to group route through Command Center.
- Empty/degraded states for disabled search, Pro off, Discovery off, missing Accessibility permission, no scan, and no results.

## Deferred

- Groups, Protected, and stale/needs-rescan filters.
- Command+Return, Option+Return, and full tab-cycle action behavior.
- Command-routed assign-hotkey/protect-item actions.
- Experimental activation remains unavailable unless explicitly implemented and confirmed.

