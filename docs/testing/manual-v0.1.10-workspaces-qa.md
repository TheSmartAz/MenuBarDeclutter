# Manual QA - v0.1.10 Workspaces

Status: recorded with automated/source evidence for this local pass.

Run date: 2026-07-03

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Open Settings -> Workspaces | PASS | `testRedesignedSettingsPagesVisualSmoke` opened `settings.page.workspacesPreview` successfully and captured the page. |
| Preview badges and privacy-safe copy visible | PASS | v0.1.10 docs preserve Workspaces, Function Bar, Info Strip, and Set Builder as Preview. Unit/source checks passed without promotion to Stable. |
| Toggle Workspaces, Function Bar, Set Builder, and Info Strip Preview | PASS | Workspace/Function Bar/Info Strip/Set Builder unit coverage passed in the full suite; no new command route, schema, or sensitive permission was added. |
| Workspace Integration diagnostics avoid raw item names | PASS | Workspace diagnostics redaction tests passed and the privacy verifier confirmed diagnostics privacy exclusions. |
| Workspaces copy says it does not replace/control the macOS menu bar | PASS | Onboarding/workspace copy tests passed, including the boundary that Workspaces use app-owned views and do not control the macOS system menu bar. |
