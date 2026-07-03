# Backup and Restore

MenuBarDeclutter can export a local JSON settings package and can restore from MenuBarDeclutter backup packages. This is local-only and does not use cloud sync, telemetry, or network access.

## What Export Includes

The v0.1.10 package schema records:

- app name
- app version
- schema/package version
- export kind
- redaction mode
- included sections
- created date

The package can include supported settings, profiles, groups/collections, dynamic hotkeys, spacer items, and Private Access policy settings.

## What Export Omits

Privacy-safe exports intentionally omit volatile or sensitive state:

- active unlock sessions
- last authentication status
- last Accessibility permission status
- dogfood run IDs and dogfood enablement
- menu bar spacing apply state
- live search text
- selected item identity
- screenshots and screen contents
- Accessibility snapshots by default
- protected group names and protected item refs
- protected hotkey targets

## Safe Import

Import is a safe, explicit flow:

1. Choose a local JSON package.
2. MenuBarDeclutter decodes it and performs a dry-run preview.
3. Dry-run does not mutate settings and does not create a backup.
4. Confirm Apply Safe Import.
5. MenuBarDeclutter creates a local backup immediately before applying changes.
6. If apply fails after mutation starts, MenuBarDeclutter rolls back to the pre-apply snapshot.

Safe import is merge-by-identity for profiles, groups, hotkeys, and spacers. It does not delete local-only objects.

Safe import skips risky enablement from imported packages unless the operation is an explicit local backup restore:

- Icon Moving
- Smart Triggers
- Menu Bar Spacing Labs
- Launch at Login system state
- dogfood settings
- permission status
- active Private Access unlock state

## Local Backup Restore

Restoring the latest local backup creates a new backup first, then applies the backup package. Local backup restore is allowed to restore saved experimental feature flags because the backup came from this app on this machine.

Launch at Login system state, permission grants, dogfood state, active unlock sessions, and other volatile state still remain outside restore.

## Not Supported as Stable

These remain Preview or deferred in v0.1.10:

- selective UI import beyond the supported safe sections
- profile packs
- group packs
- migration assistant workflows
- Bartender, Ice, SaneBar, or other competitor auto-import
- destructive full restore
- cloud sync
