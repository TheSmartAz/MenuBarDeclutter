# Import Export v0.1.1

Status: Preview, with diagnostics and dogfood export Stable.

Import/export is local only. No cloud sync, network access, telemetry, or remote config is used.

## Implemented

- Full settings package export with app version, schema version, export kind, created date, redaction mode, omitted settings, profiles, groups, hotkeys, spacer items, and Private Access policy metadata.
- Real setting values are exported; placeholder values and the deprecated primary separator setting are omitted.
- Dry-run import, backup creation, and explicit safe apply.
- Safe apply merges profiles, groups, hotkeys, and spacers by identity, skips conflicting hotkeys, leaves Launch at Login/Login Items system state unchanged, and does not enable Icon Moving, Smart Triggers, or Menu Bar Spacing Labs from an import unless explicitly allowed.
- Latest-backup restore is available from the Import / Export assistant. It reapplies the latest local settings package backup with experimental flags allowed so a pre-import state can be recovered.
- Protected groups are redacted by default.

## Deferred

- Separate Safe Support Export, Profile Pack, and Group Pack flows in one unified picker.
- Selectable section import UI.
- Destructive full restore, backup browsing, and selective rollback UI.
- Competitor auto-import beyond guided/manual migration.
