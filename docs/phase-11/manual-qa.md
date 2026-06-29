# Phase 11 Manual QA

## Groups

1. Open Settings > Groups.
2. Create a group with a bundle ID ref.
3. Add a visible menu bar item from the picker when Pro snapshots are available.
4. Enable "Show as status item" and confirm an app-owned status item appears.
5. Open the group panel and navigate with arrow keys.
6. Press Escape and confirm the panel closes.
7. Mark the group protected and confirm protected previews redact item names.

## Private Access

1. Open Settings > Private Access.
2. Enable Private Access and at least one protected surface.
3. Run Test Authentication.
4. Confirm successful unlock opens a timed session.
5. Clear the session and confirm protected actions prompt again.
6. Disable Private Access and confirm Basic Mode still works.

## Dynamic Hotkeys

1. Open Settings > Hotkeys.
2. Enable dynamic hotkeys.
3. Add a group or layout binding.
4. Add a duplicate binding and confirm conflict warning.
5. Disable dynamic hotkeys and confirm registrations are removed.

## App Intents

1. Open Settings > Automation.
2. Toggle App Intents off and confirm Shortcuts commands degrade.
3. Toggle profile apply on and apply a profile from Shortcuts.
4. Toggle Labs access on and run a Labs-gated command.
5. Enable Safe Mode and confirm only safe commands run.

## Import / Export

1. Open Settings > Import Export.
2. Export a package.
3. Import the package in dry-run mode.
4. Confirm conflicts and risky experimental flags are visible.
5. Create a backup before apply.

## Privacy

1. Run `scripts/verify_privacy_boundary.sh`.
2. Export diagnostics.
3. Confirm protected group names, protected hotkey targets, personal file
   paths, screenshots, screen contents, and network data are absent.
