# Private Access v0.1.1

Status: Preview.

Private Access gates MenuBarDeclutter-owned actions with LocalAuthentication. It is not encryption and does not hide third-party menu bar items that are already visible in the system menu bar.

## Implemented

- Optional protection for Always Hidden reveal, Find Icon, Second Bar, Icon Moving, Spacing Labs commands, protected groups, profile apply, and App Intent/URL automation commands.
- Unlock sessions with configurable duration and manual clear.
- LocalAuthentication outcomes for success, cancel, failure, and unavailable states.
- Safe Mode clears/suppresses optional protected workflows while leaving Basic Mode recovery usable.
- Diagnostics redact protected resource names and group IDs.

## Deferred

- A full protected-resource inventory/editor.
- Richer per-command unlock prompts outside the status-menu path.
- Manual QA for Touch ID success/cancel/unavailable/failure and session expiration on target hardware.

