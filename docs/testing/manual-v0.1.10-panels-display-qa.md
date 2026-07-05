# Manual QA - v0.1.10 Panels and Display

Status: recorded. App-owned panel smoke tests passed; Workspaces panel launch automation now compiles, but the local UI runner could not execute the new focused panel tests. Physical external-display coverage is blocked in this local session.

Run date: 2026-07-03; continuation 2026-07-04

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Show Function Bar from Workspaces settings | PARTIAL / BLOCKED-INFRA | Added focused UI coverage for opening Function Bar from Workspaces settings, plus a UI-testing launch argument that enables the Workspaces, Function Bar, and Info Strip preview gates in isolated UI-test storage. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/ui-build-for-testing CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO` passed, so the test compiles. Local focused UI execution still fails before assertions: one run timed out enabling automation mode, and a follow-up failed with `IDELaunchServicesLauncher - Failed to Launch`. Hands-on clicking remains unperformed. |
| Show Info Strip from Workspaces settings | PARTIAL / BLOCKED-INFRA | Added focused UI coverage for opening Info Strip from Workspaces settings and enabling the active workspace Info Strip config in UI-testing state. The UI test target compiles in the build-for-testing pass above. Local focused UI execution still fails before assertions: one run timed out enabling automation mode, and a follow-up failed with `IDELaunchServicesLauncher - Failed to Launch`. Hands-on clicking remains unperformed. |
| Confirm panels are app-owned and dismiss cleanly | PASS | `testFloatingPanelsVisualSmoke` passed for Find Icon and Second Bar unavailable panel; `testSearchPanelEscapeDismisses` passed. No Screen Recording or system menu bar control was introduced. |
| Available display/notch coverage | PARTIAL | Local built-in MacBook Pro display was used by UI screenshots. Unit test coverage includes modeled notch avoidance, but hands-on notch edge placement was not performed. |
| External display coverage | BLOCKED | No external display was available in this local session. |

## 2026-07-04 Follow-Up Evidence

- Added UI anchors for Workspaces quick actions and preview controls so the focused panel tests can target the intended controls instead of label-only matching.
- Added `--ui-testing-enable-workspace-panels` to seed Workspaces/Function Bar/Info Strip preview gates only under UI testing.
- Focused UI test execution remained blocked locally before app assertions: first by `Timed out while enabling automation mode`, then by `IDELaunchServicesLauncher - Failed to Launch (Failed to send resume to target process...)` after terminating the installed app and rerunning.
- `system_profiler SPDisplaysDataType` still reports only the built-in Liquid Retina XDR display, so external display QA remains unavailable.
