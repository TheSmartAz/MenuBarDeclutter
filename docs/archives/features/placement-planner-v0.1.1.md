# Placement Planner v0.1.1

Status: Preview.

Placement Planner is the Pro-assisted, non-mutating placement layer for Arrange. It reads local Accessibility metadata only after the normal Pro gates are satisfied, then suggests manual placement instructions.

## Gates

Planner is available only when:

- Pro Mode is enabled.
- Accessibility Discovery is enabled.
- macOS Accessibility permission is granted.
- Safe Mode is inactive.
- A non-stale scan is available.

Missing gates produce an unavailable or degraded state. Guided Manual Arrange remains usable without Planner.

## Recommendations

The pure planner model can return:

- keep visible
- move to hidden
- move to always hidden
- review new item
- stale metadata
- likely system item
- no recommendation
- needs manual placement

Planner output is advisory. It does not move icons and does not execute CGEvent dragging.

## Item Preferences

Planner rows can store a local preference for a hashed item key:

- keep visible
- hide
- always hide
- review later

Preferences bias future recommendations and visible row badges. They are persisted locally in Application Support and are still advisory: changing a preference never moves an item, changes a zone, or triggers Assisted Move by itself.

## Privacy

Diagnostics should record counts by recommendation type, not raw item titles, bundle identifiers, selected item IDs, protected names, or raw preference identities by default.

## Current Scope

The current implementation includes the pure recommendation model, Arrange page degraded states, and a short visible recommendation list when live scan data is available. Planner rows now include privacy-safe display titles/subtitles, new/favorite badges from hashed local memory, current and suggested zones, persisted hashed item preferences, and command hooks for highlight, Second Bar, owning app, group creation, and Assisted Move dry-run.

A larger dedicated planner surface remains future hardening.
