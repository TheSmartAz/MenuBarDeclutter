# Phase 11 Hotkeys QA

## Steps

1. Open Settings > Hotkeys.
2. Confirm dynamic hotkeys are off by default.
3. Enable dynamic hotkeys.
4. Add a binding for Full Menu Bar Mode.
5. Add a binding for a group.
6. Add a duplicate key combination.
7. Confirm conflict messaging appears and conflicting binding is not registered.
8. Disable all dynamic hotkeys.
9. Enter Safe Mode and confirm dynamic hotkeys unregister.

## Expected

- Static global hotkeys continue to work.
- Dynamic hotkeys respect max binding count.
- Protected actions require Private Access when configured.
- Diagnostics do not export protected target identity.
