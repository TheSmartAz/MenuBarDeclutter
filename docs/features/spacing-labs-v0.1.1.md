# Spacing Labs v0.1.1

Status: Labs, dry-run by default.

Menu Bar Spacing Labs concerns global menu bar spacing defaults. Because that affects system-wide behavior, mutation paths stay behind the Labs gate and run in dry-run mode unless an explicit internal flag enables undocumented defaults writes.

## Implemented

- Labs toggle and local preset preference.
- Custom spacing preference fields.
- Command Center gates spacing commands behind Labs and returns dry-run results by default.
- App Intent/Automation label uses "Preview Layout Spacing Preset".
- Safe import does not enable Spacing Labs from an imported package by default.
- Privacy and release docs state that no automatic system process restart occurs.
- The spacing service has backup, restore, apply, and reset code paths, but real writes are disabled by default.

## Deferred

- Shipping/user-facing real global defaults mutation.
- Automatic SystemUIServer or system process restart.
- Strong release claims for persisted backup/restore/rollback until hands-on manual QA covers the real-write path.
