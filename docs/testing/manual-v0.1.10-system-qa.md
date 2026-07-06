# Manual QA - v0.1.10 System

Status: recorded. Automated/source/release gates passed; hands-on-only checks are marked partial where not run. A 2026-07-06 installed smoke rerun passes against the refreshed dry-run app; direct release verification still reports expected non-notarized dry-run `spctl` and stapler warnings.

Run date: 2026-07-03; continuations 2026-07-04 and 2026-07-06

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Launch app from a local build | PASS | Final `scripts/build_release.sh --dry-run --install --verify-installed` installed `/Applications/MenuBarDeclutter.app` at 2026-07-06 01:24 PDT; installed-app verification passed. UI launch tests passed in light and dark appearance earlier in the run. The 2026-07-06 installed smoke launched the refreshed installed app and completed successfully. Direct release verification still reports expected dry-run `spctl` rejection and missing stapler ticket for the non-notarized artifact. |
| Basic Mode controls without Pro permissions | PASS | UI and unit tests passed with `--ui-testing` defaults resetting Pro Mode and Accessibility Discovery off. Privacy verifier confirmed Basic Mode remains permission-free, the only sensitive usage string is scoped to the separate Accurate Icons Screen Recording path, and no network entitlements are present. |
| Settings opens to the eight-section sidebar | PASS | `testSettingsSidebarUsesFocusedSections`, `testRedesignedSettingsPagesVisualSmoke`, and the installed focused screenshot QA passed against General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, and Advanced. |
| No unexpected Basic Mode permission prompts | PASS | Final `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed and UI privacy workflow kept Request Permission disabled until explicit Pro controls. |
| Status menu daily-use scan | PASS | Final menu builder tests cover the Basic Mode, Find & Rescue, Layout, and Support section order; the installed focused screenshot QA passed after adding section headers. |
| Safe Mode and Recovery open | PARTIAL | Recovery UI workflow passed. Safe Mode logic and recovery actions passed unit/source coverage. The 2026-07-06 installed smoke verified the one-shot next-launch Safe Mode flag is consumed by the refreshed installed app and that the app relaunches normally afterward. Option-launch hands-on Safe Mode was not performed in this local run. |

## 2026-07-04 Follow-Up Evidence

- `scripts/build_release.sh --dry-run --install --verify-installed` passed and refreshed `/Applications/MenuBarDeclutter.app`.
- `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed, including installed-bundle checks for `LSUIElement`, `menubardeclutter://`, the Accurate Icons Screen Recording usage string, absent Apple Events/Input Monitoring strings, and no network entitlements.
- `/Applications/MenuBarDeclutter.app/Contents/Info.plist` reads back `CFBundleShortVersionString = 0.1.10`, `CFBundleVersion = 11`, `LSUIElement = true`, and the Accurate Icons `NSScreenCaptureUsageDescription`.
- `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app` passed: installed app launched, URL commands reused the installed PID, installed privacy verification passed, no network sockets were observed, the one-shot Safe Mode flag was consumed, and normal relaunch succeeded.
- `spctl --assess --type execute -vvv /Applications/MenuBarDeclutter.app` still returns `Too many open files`; the controlled launch probe captured syspolicyd UNIX error 24 / SecStaticCode failures while the app itself stayed running.

## 2026-07-06 Follow-Up Evidence

- `scripts/build_release.sh --dry-run --install --verify-installed` passed and refreshed `/Applications/MenuBarDeclutter.app` at 2026-07-06 01:24 PDT.
- `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app` passed: installed app launched, URL commands reused the installed PID, installed privacy verification passed, no network sockets were observed, the one-shot Safe Mode flag was consumed, and normal relaunch succeeded.
