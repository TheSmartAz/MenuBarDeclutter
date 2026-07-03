# Phase 23 Progress - v0.1.10 Release Hardening

Status: complete for automated/local release gates; physical hardware QA remains recorded as partial or blocked where this local setup could not exercise it.

Date: 2026-07-03

## Implemented

- Updated release identity to `MARKETING_VERSION = 0.1.10` and `CURRENT_PROJECT_VERSION = 11`.
- Updated current-facing release tooling/help copy to the v0.1.10 release line.
- Updated current-facing README, roadmap, support, feature, privacy, design, release, and manual QA docs for v0.1.10.
- Created `docs/plans/PHASE-23.md`.
- Created v0.1.10 release hardening docs under `docs/release/`, `docs/privacy/`, `docs/design/`, `docs/features/`, and `docs/testing/`.
- Added stable UI test anchors for Privacy Pro Discovery and Second Bar unavailable states.
- Hardened release-gate UI tests around Settings visual smoke, Arrange, floating panels, and Privacy Pro Discovery.
- Added status menu section headers for faster daily scanning and VoiceOver context.
- Added keyboard-selection accessibility hints to Search, Second Bar, and Settings command palette result rows.
- Hardened dry-run Gatekeeper verification so repeated local `spctl` resource errors remain warnings only when notarization is not required.
- Fixed release-blocking checks found during the gate run:
  - Info Strip tile provider icon lookup now matches the current provider IDs.
  - Settings command palette tests can read `SettingsSection` help/search metadata.
  - Advanced feature directory exposes visible entries for tests without duplicating filtering logic.
  - Onboarding privacy copy avoids literal framework names that the privacy verifier treats as capability additions.

## Gate Results

| Gate | Result | Notes |
| --- | --- | --- |
| `xcodebuild -list` | PASS | Schemes: `MenuBar-Manager`, `MenuBarDeclutter`, `MenuBarFixtureApp`. Targets include app, unit tests, UI tests, and fixture app. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS | Final run ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | BLOCKED-INFRA | Latest direct full-test attempts hit an Xcode LaunchServices assertion before meaningful test execution: `IDELaunchServicesLauncher.m:413`, `childPID > 0`, exit 134. |
| `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Latest split-lane build ended with `** TEST BUILD SUCCEEDED **`. |
| `xcodebuild test-without-building -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests` | PASS | Latest unit run: 564 Swift/unit tests in 77 suites passed. Result bundle: `Test-MenuBarDeclutter-2026.07.03_04-44-54--0700.xcresult`. |
| `xcodebuild test-without-building -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests` | PASS | Latest UI split run: 17 UI tests passed with 0 failures. Result bundle: `Test-MenuBarDeclutter-2026.07.03_04-32-46--0700.xcresult`. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Source and installed bundle checks passed after the final polish: no ScreenCaptureKit import/link, no Screen Recording/Apple Events/Input Monitoring usage strings, no network entitlements, and no direct network/analytics SDK usage. |
| `scripts/build_release.sh --dry-run` | PASS | Archive, export, package, and artifact verification passed. Artifact: `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip`; the default dry-run packaging flow does not create a non-alpha zip copy. Expected non-notarized dry-run `spctl` and stapler warnings were non-blocking. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS | Final rerun after accessibility/menu polish installed `/Applications/MenuBarDeclutter.app` at 2026-07-03 04:41 PDT; installed-app verification passed with version `0.1.10`, build `11`, privacy strings absent, no network entitlements, hardened runtime metadata present, and no ScreenCaptureKit link. |
| `OUTPUT_DIR=/tmp/MenuBarDeclutter-installed-focused-qa-after-polish-2026-07-03 CAPTURE_ATTEMPTS=2 scripts/qa_capture_ui_screenshots.sh --app-path /Applications/MenuBarDeclutter.app --focused-only` | PASS | Captured the focused installed surfaces and floating panels; contact sheet: `/tmp/MenuBarDeclutter-installed-focused-qa-after-polish-2026-07-03/contact-sheet.png`. |
| Targeted v0.2 overclaim search | PASS | Hits were only v0.2 guardrails or historical progress notes, not current shipped claims or artifact names. |
| Targeted forbidden capability search | PASS | Hits were verifier scripts only; no app code or project file additions for ScreenCaptureKit, Screen Recording usage strings, Apple Events usage strings, Input Monitoring usage strings, direct network clients, analytics SDKs, telemetry, cloud sync, or private API additions. |
| Current-facing v0.1.9 stale search | PASS | Hits are deliberate v0.1.9 baseline context in v0.1.10 docs, not stale build/version settings. |
| `git diff --check` | PASS | No whitespace errors. |

## Manual QA Status

Recorded in:

- `docs/testing/manual-v0.1.10-system-qa.md`
- `docs/testing/manual-v0.1.10-workspaces-qa.md`
- `docs/testing/manual-v0.1.10-panels-display-qa.md`
- `docs/testing/manual-v0.1.10-privacy-qa.md`
- `docs/testing/manual-v0.1.10-results.md`

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`, v0.1.10 build 11.

## Open Blockers

- No automated, privacy, packaging, or installed-app blocker remains.
- Physical external display coverage is blocked in this local session because no external display was available.
- Hands-on notch and Option-launch Safe Mode checks were not performed; they are recorded as partial because automated/unit/UI coverage passed but physical confirmation was not run.
