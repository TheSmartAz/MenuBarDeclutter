# Manual QA - v0.1.10 System

Status: recorded. Automated/source/release gates passed; hands-on-only checks are marked partial where not run.

Run date: 2026-07-03

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Launch app from a local build | PASS | Final `scripts/build_release.sh --dry-run --install --verify-installed` installed `/Applications/MenuBarDeclutter.app` at 2026-07-03 04:41 PDT; installed-app verification passed. UI launch tests passed in light and dark appearance. |
| Basic Mode controls without Pro permissions | PASS | UI and unit tests passed with `--ui-testing` defaults resetting Pro Mode and Accessibility Discovery off. Privacy verifier confirmed Basic Mode has no sensitive usage strings or network entitlements. |
| Settings opens to the eight-section sidebar | PASS | `testSettingsSidebarUsesFocusedSections`, `testRedesignedSettingsPagesVisualSmoke`, and the installed focused screenshot QA passed against General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, and Advanced. |
| No unexpected Basic Mode permission prompts | PASS | Final `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed and UI privacy workflow kept Request Permission disabled until explicit Pro controls. |
| Status menu daily-use scan | PASS | Final menu builder tests cover the Basic Mode, Find & Rescue, Layout, and Support section order; the installed focused screenshot QA passed after adding section headers. |
| Safe Mode and Recovery open | PARTIAL | Recovery UI workflow passed. Safe Mode logic and recovery actions passed unit/source coverage, but Option-launch hands-on Safe Mode was not performed in this local run. |
