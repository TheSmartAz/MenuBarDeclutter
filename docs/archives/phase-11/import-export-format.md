# Phase 11 Import/Export Format

## Package

Exports use a user-selected JSON package encoded by `SettingsExportPackage`.

```json
{
  "packageVersion": 1,
  "appVersion": "0.1.0",
  "createdAt": "2026-06-29T00:00:00Z",
  "settings": {},
  "profiles": [],
  "groups": [],
  "hotkeyBindings": [],
  "spacerItems": [],
  "privateAccessPolicy": null,
  "includeAXSnapshots": false
}
```

## Field Notes

- `packageVersion`: current schema version. Unsupported versions are reported
  as dry-run conflicts.
- `settings`: string-keyed settings map. Experimental flags are detected before
  import.
- `profiles`: profile summaries and pack metadata.
- `groups`: full icon group models, see `group-schema.md`.
- `hotkeyBindings`: full dynamic hotkey models, see `hotkey-schema.md`.
- `spacerItems`: app-owned spacer/divider models.
- `privateAccessPolicy`: policy preferences only; active unlock sessions are
  never exported.
- `includeAXSnapshots`: reserved flag. AX snapshots are not included by default.

## Import Rules

1. User selects a package file.
2. The app decodes JSON and runs a dry-run.
3. Conflicts and risky experimental flags are shown before apply.
4. A backup is created before import.
5. Import does not move third-party icons or bypass Private Access.

## Privacy Rules

- No automatic competitor config scraping.
- No personal file paths in diagnostics export.
- User-selected import/export paths should be shown only in immediate UI
  context, not stored in diagnostics.
