# Manual QA - v0.1.7 Info Strip

- Launch with Info Strip Preview disabled and confirm no panel appears.
- Enable Workspaces Preview and Info Strip Preview.
- Enable Info Strip for one Workspace.
- Select at least three local tiles.
- Open Info Strip from Settings and from the status menu.
- Confirm current tile renders.
- Confirm manual Next advances if visible.
- Confirm unavailable tile list shows a clear empty state.
- Disable Info Strip Preview and confirm the panel closes or becomes unavailable.
- Enter Safe Mode and confirm Info Strip is suppressed.
- Export diagnostics and confirm raw item identities and protected names are absent.

## Run Record - 2026-07-02

- PASS: Launched the Debug build in isolated UI-testing mode with Info Strip Preview initially disabled.
- PASS: Enabled Workspaces Preview, Function Bar Preview, Set Builder Preview, and Info Strip Preview from Advanced -> Workspaces Preview.
- PASS: Enabled Info Strip for the active Default workspace, kept seven selected local tile providers, and saved the workspace.
- PASS: Opened `Info Strip Preview` and observed a Battery tile render with Function Bar, Next, and Close controls.
- PASS: Waited past the configured 8 second rotation interval and observed rotation to the recovery status tile.
- NOT COVERED: Status menu open path, Safe Mode suppression, diagnostics export redaction, and unavailable tile empty-state visual review remain covered by automated/unit checks or require a separate release QA pass.
