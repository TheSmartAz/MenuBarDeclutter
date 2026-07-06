# Manual QA - v0.1.10 Privacy

Status: recorded. Source, project, installed-bundle, entitlement, linkage, and no-network socket checks passed after the 2026-07-06 installed-app rerun.

Run date: 2026-07-03; continuation 2026-07-06

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Basic Mode does not request Accessibility | PASS | UI privacy workflow passed with Pro Mode off by default; Request Permission stayed disabled until explicit Pro controls. Final privacy verifier passed against source and installed app. |
| Workspaces Preview does not request Screen Recording | PASS | Workspaces Preview stayed independent from Accurate Icons. The installed app declares `NSScreenCaptureUsageDescription` only for the separate Accurate Icons opt-in path, and source/project searches found ScreenCaptureKit scoped to `MenuBarIconCapture`. |
| No network access required for Preview surfaces | PASS | Privacy verifier found no network entitlements and no direct network client APIs or analytics SDK names in app code. The 2026-07-06 installed smoke observed no network sockets for the running installed app. |
| Diagnostics export excludes protected names/raw item metadata | PASS | Diagnostics exporter/source tests passed, including privacy exclusions and redacted aggregate metadata paths. |
| No unscoped ScreenCaptureKit, Apple Events, Input Monitoring, telemetry, cloud sync, or private API additions | PASS | Targeted searches found ScreenCaptureKit only in the Accurate Icons module and verifier scripts. Installed app verification confirmed the Screen Recording usage string is scoped to Accurate Icons and no Apple Events or Input Monitoring usage strings are present. |

## 2026-07-06 Follow-Up Evidence

- `scripts/build_release.sh --dry-run --install --verify-installed`: PASS, refreshed and verified `/Applications/MenuBarDeclutter.app` at 2026-07-06 05:38 PDT.
- `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app`: PASS, including installed privacy verification, no-network socket probe, URL command reuse with PID `82129`, and one-shot Safe Mode flag consumption with normal relaunch PID `83323`.
- `showSecondBarAppIntentUsesFullReadinessGate`: PASS in the app-hosted test bundle; Shortcuts/App Intent `Show Second Bar` blocks before execution when Accurate Icons or Screen Recording are missing and returns explicit gate results for both states.
- `secondBarURLUsesFullReadinessGate`: PASS in the app-hosted test bundle; `menubardeclutter://second-bar` blocks before execution when Accurate Icons or Screen Recording are missing and does not bypass the shared Second Bar readiness chain.
- Runtime Accessibility and Screen Recording permission prompt behavior for Pro Second Bar setup remains hands-on manual QA; no automatic prompt was exercised by the installed smoke.
