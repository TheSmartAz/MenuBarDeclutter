# Manual QA Results - v0.1.10

Status: recorded. Automated/source/privacy/release gates passed; physical hardware-only checks are partial or blocked where unavailable.

Run date: 2026-07-03

App build: v0.1.10 build 11

## Environment

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Build source: local repository dry-run build.
- Installed app: `/Applications/MenuBarDeclutter.app`.

## Result Summary

| Gate | Result | Notes |
| --- | --- | --- |
| Basic Mode | PASS | Build/test/privacy gates passed; Basic Mode remains permission-free. |
| Workspaces | PASS | Workspaces Settings visual smoke and unit/source privacy boundary checks passed. |
| Function Bar | PARTIAL | Unit/source coverage passed; hands-on live panel toggle from Workspaces was not performed. |
| Info Strip | PARTIAL | Unit/source coverage passed; hands-on live panel toggle from Workspaces was not performed. |
| Set Builder | PASS | Set Builder/Workspace preview unit and source gates passed with no schema or permission expansion. |
| Find & Rescue | PASS | UI tests passed for Find & Rescue primary actions, Search unavailable state, floating Find Icon, and Escape dismissal. |
| Recovery/Safe Mode | PARTIAL | Recovery UI workflow passed; Safe Mode source/unit coverage passed. Option-launch hands-on Safe Mode was not performed. |
| Privacy prompts | PASS | Privacy UI test and installed-bundle privacy verification passed. |
| Diagnostics export | PASS | Diagnostics exporter tests and privacy verifier passed; manual file export was not separately performed. |
| Display/notch coverage | PARTIAL | UI screenshots used the built-in display and modeled notch avoidance tests passed; hands-on notch edge placement was not performed. External display coverage is blocked. |

## Evidence

- Pre-Phase-23 visual review screenshots: `docs/testing/current-ui-review-2026-07-03/`.
- Focused UI optimization screenshots: `docs/testing/ui-optimization-2026-07-03/`.
- Final full test result bundle: `Test-MenuBarDeclutter-2026.07.03_02-47-32--0700.xcresult`.
- Release artifacts: `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.10.zip`.
