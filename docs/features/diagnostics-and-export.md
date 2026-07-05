# Diagnostics And Export

Diagnostics is the local supportability surface for runtime state, event logs, health, Pro discovery, search, Second Bar, icon moving, profiles, triggers, Launch at Login, and dogfood state.

## What It Does

- Shows an in-memory structured event log.
- Supports severity filtering and category filtering.
- Copies a selected event summary to the pasteboard.
- Exports filtered diagnostics as TXT or JSON.
- Shows screen frame metadata, not screen contents.
- Shows live Basic Mode state: visibility, separator lengths, hotkey, hover, auto-rehide, and automation pause.
- Shows Pro discovery state: Accessibility permission, scan counts, zone counts, last scan time, and AX failures.
- Shows Find Icon, Second Bar, Icon Moving, profile, trigger, Launch at Login, health, Safe Mode, and dogfood state.
- Exports a standalone health report.
- Exports local dogfood bundles when Dogfood Mode is enabled.

## User Flow

1. Open Show Diagnostics from the status menu, or use Settings -> Recovery for health and export actions.
2. Review Health first if the app looks unhealthy.
3. Filter events by severity or category.
4. Copy a selected event or export filtered diagnostics.
5. Export a health report or dogfood bundle when needed for local QA.

## Privacy And Permissions

Diagnostics export is explicit user action only. Exports include app version, macOS version, architecture, screen frames, current settings, optional dogfood run metadata, and filtered structured logs. They exclude screenshots, screen contents, live search text, selected item identity, personal file paths by default, network data, telemetry, and cloud sync.

## Implementation

- `MenuBar-Manager/Settings/DiagnosticsSettingsView.swift`
- `MenuBar-Manager/Core/DiagnosticsLogger.swift`
- `MenuBar-Manager/Core/DiagnosticsExporter.swift`
- `MenuBar-Manager/Core/LiveDiagnosticsStatus.swift`
- `MenuBar-Manager/App/AppEnvironmentLiveStatusSynchronizer.swift`

## Verification

- `MenuBar-ManagerTests/DiagnosticsLoggerTests.swift`
- `MenuBar-ManagerTests/DiagnosticsExportTests.swift`
- `MenuBar-ManagerTests/LiveDiagnosticsStatusTests.swift`
- `MenuBar-ManagerTests/HealthReportTests.swift`
- Manual QA: `docs/testing/manual-qa.md`
- Privacy QA: `docs/testing/privacy-qa.md`

## Known Limitations

- Diagnostics UI can display local AX metadata from live scans, but exports are the privacy-filtered artifact.
- Export save locations are user-chosen through `NSSavePanel`.
- Runtime network observation still requires manual `lsof` or `nettop` QA outside the app.
