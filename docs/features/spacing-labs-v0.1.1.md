# Spacing Labs v0.1.1

Status: Labs, safely deferred for apply/restore/reset.

Menu Bar Spacing Labs concerns global menu bar spacing defaults. Because that affects system-wide behavior, `v0.1.1` keeps mutation paths guarded and preview-only unless a future build completes reliable backup, restore, reset, and manual QA.

## Implemented

- Labs toggle and local preset preference.
- Custom spacing preference fields.
- Command Center returns dry-run-only for spacing apply commands.
- App Intent/Automation label uses "Preview Layout Spacing Preset".
- Safe import does not enable Spacing Labs from an imported package by default.
- Privacy and release docs state that no automatic system process restart occurs.

## Deferred

- Apply Preset, Restore Previous, Reset to System Default, View Backup, and related UI.
- Actual global defaults mutation from App Intents or URL automation.
- Reliable persisted backup/restore/rollback manual QA.

