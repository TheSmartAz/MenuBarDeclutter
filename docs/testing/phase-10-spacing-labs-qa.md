# Phase 10 Spacing Labs QA

## Preconditions

- Spacing Labs disabled at start.

## Steps

1. Open Settings > Layout.
2. Confirm Spacing Labs are off by default.
3. Enable Labs intentionally.
4. Apply the compact preset.
5. Apply the comfortable preset.
6. Apply a custom preset.
7. Restore previous values.
8. Reset to system defaults.
9. Restart the app and confirm stored status is visible.

## Expected

- Backup is created before first apply.
- The app never restarts SystemUIServer or Control Center automatically.
- Labs actions are logged through diagnostics.
- Private Access can protect Labs when enabled.
