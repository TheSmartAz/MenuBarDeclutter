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
| Basic Mode | PASS | Split build/test/privacy/release gates passed; Basic Mode remains permission-free. |
| Workspaces | PASS | Workspaces Settings visual smoke and unit/source privacy boundary checks passed. |
| Function Bar | PARTIAL | Unit/source coverage passed; hands-on live panel toggle from Workspaces was not performed. |
| Info Strip | PARTIAL | Unit/source coverage passed; hands-on live panel toggle from Workspaces was not performed. |
| Set Builder | PASS | Set Builder/Workspace preview unit and source gates passed with no schema or permission expansion. |
| Find & Rescue | PASS | UI tests passed for Find & Rescue primary actions, Search unavailable state, floating Find Icon, and Escape dismissal. |
| Recovery/Safe Mode | PARTIAL | Recovery UI workflow passed; Safe Mode source/unit coverage passed. Option-launch hands-on Safe Mode was not performed. |
| Privacy prompts | PASS | Privacy UI test and installed-bundle privacy verification passed after the final installed app rerun. |
| Diagnostics export | PASS | Diagnostics exporter tests and privacy verifier passed; manual file export was not separately performed. |
| Display/notch coverage | PARTIAL | UI screenshots used the built-in display and modeled notch avoidance tests passed; hands-on notch edge placement was not performed. External display coverage is blocked. |

## Evidence

- Pre-Phase-23 visual review screenshots: `docs/testing/current-ui-review-2026-07-03/`.
- Focused UI optimization screenshots: `docs/testing/ui-optimization-2026-07-03/`.
- Direct latest `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` attempts were blocked by an Xcode LaunchServices assertion before meaningful test execution: `IDELaunchServicesLauncher.m:413`, `childPID > 0`, exit 134.
- Latest split unit result bundle: `Test-MenuBarDeclutter-2026.07.03_04-44-54--0700.xcresult` with 564 tests in 77 suites passed.
- Latest split UI result bundle: `Test-MenuBarDeclutter-2026.07.03_04-32-46--0700.xcresult` with 17 UI tests passed.
- Final installed focused screenshot QA contact sheet: `/tmp/MenuBarDeclutter-installed-focused-qa-after-polish-2026-07-03/contact-sheet.png`.
- Release artifacts refreshed at 2026-07-03 04:41 PDT: `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.10.zip`.
