# Workspaces v0.1.4 Foundation

Workspaces in v0.1.4 are Preview/Foundation only. They store local app-owned configurations that future Function Bar and Info Strip features can use. Switching a workspace in v0.1.4 does not move third-party menu bar icons, replace the macOS menu bar, apply physical layouts, or start automation.

Workspace data is stored as local JSON under MenuBarDeclutter Application Support. The store has schema versioning, validation, safe defaults, repair, and corruption backup.

Diagnostics may report counts, validation issue totals, redacted workspace IDs, missing reference counts, and store load status. Diagnostics must not export raw workspace item names, raw menu bar item identities, protected group names, live search text, or file paths by default.

Workspaces do not use Screen Recording, ScreenCaptureKit, private menu bar APIs, Apple Events scripting/control, Input Monitoring, network access, telemetry, cloud sync, or broad third-party activation.
