# Phase 11 Competitor Import Roadmap

Date: 2026-06-29

## Current Status

Phase 11 implements MenuBarDeclutter export/import and profile packs. It does
not auto-scrape competitor configuration files and does not claim compatibility
with any third-party app's private, undocumented, GPL, or source-available
formats.

## Non-Goals

- No automatic discovery of competitor files.
- No reading hidden application support folders without explicit user choice.
- No Apple Events or AppleScript automation.
- No ScreenCaptureKit, screenshots, or screen contents.
- No network lookup of app metadata.
- No copying or adapting GPL/source-available competitor implementations.
- No import flow that silently enables icon moving, spacing Labs, smart
  triggers, or other experimental features.

## Future Import Shape

Any competitor import should be user-selected and schema-driven:

1. The user chooses a JSON or CSV file explicitly.
2. The importer validates a documented schema.
3. The app runs a dry-run first.
4. The dry-run shows groups, profiles, hotkeys, layout preferences, conflicts,
   and risky flags.
5. The app creates a backup before apply.
6. Experimental flags remain disabled unless the user explicitly opts in.
7. Import never executes icon moves or opens protected resources.

## Candidate Neutral Schema

A safe generic importer can start with these fields:

- group name,
- optional symbol and semantic color,
- bundle identifiers,
- app names,
- title contains matchers,
- optional notes,
- optional profile names.

The importer should treat unknown or missing apps as unavailable references,
not delete them. Matching should reuse `IconGroupMatcher` rules so imported
groups behave like native groups.

## Privacy Rules

- Import paths are local UI context only and should not be persisted in
  diagnostics.
- Protected group names and protected hotkey targets stay redacted in exports.
- Accessibility snapshots are excluded from exports by default.
- Import cannot bypass Private Access or Safe Mode.

## Documentation Requirement Before Implementation

Before supporting a specific third-party format, add a format note describing:

- the user-selected source file,
- the fields consumed,
- unsupported fields,
- privacy implications,
- how conflicts and experimental flags are handled,
- confirmation that no competitor source code was copied or closely adapted.
