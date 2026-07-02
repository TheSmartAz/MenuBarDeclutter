# Find & Rescue v0.1.3

Find & Rescue is the v0.1.3 daily recovery surface for locating hidden or stale menu bar metadata without Screen Recording, ScreenCaptureKit, network access, or live pixel capture.

## Current v0.1.3 Focus

- Faster panel-open and ranking paths for fixture-sized item sets.
- Ranking that favors exact and prefix matches, app/title matches, useful bundle ID matches, recents, favorites, new items, hidden items, and non-stale metadata.
- Keyboard actions that route through the same Command Center paths as visible buttons.
- Empty states for Pro Discovery off, missing Accessibility permission, no scan yet, stale scan, Safe Mode, and no matching items.
- Privacy-safe performance diagnostics that do not export live query text or raw item identity.
- Crowded and notch rescue decisions use aggregate capacity, hidden-item backlog, notch risk, active-display match, Pro availability, and command availability. Second Bar is preferred only when Pro Discovery is available; Basic fallback remains Full Menu Bar Mode or a recovery suggestion.
- Rescue explanations are visible in Find & Rescue settings and diagnostics: Second Bar opens because inline reveal may not fit, Full Menu Bar Mode temporarily reveals items, and suggestions point users toward Arrange or Apple menu bar settings.

## Boundaries

Find & Rescue remains Pro Discovery gated where it depends on Accessibility metadata. Basic Mode remains usable when Pro Discovery is off or unavailable.

Crowded/notch rescue does not inspect app menus directly. The long-app-menu pressure input is modeled as an aggregate policy signal and remains `.unknown` until a trustworthy public estimate is available.
