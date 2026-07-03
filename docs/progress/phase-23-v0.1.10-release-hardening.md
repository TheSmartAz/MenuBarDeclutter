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
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Final run: 561 Swift/unit tests in 77 suites passed, then 16 UI tests passed with 0 failures. Result bundle: `Test-MenuBarDeclutter-2026.07.03_02-47-32--0700.xcresult`. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Source and installed bundle checks passed: no ScreenCaptureKit import/link, no Screen Recording/Apple Events/Input Monitoring usage strings, no network entitlements, and no direct network/analytics SDK usage. |
| `scripts/build_release.sh --dry-run` | PASS | Archive, export, package, and artifact verification passed. Artifacts: `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.10.zip`. Expected non-notarized dry-run `spctl` and stapler warnings were non-blocking. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS | Installed `/Applications/MenuBarDeclutter.app`; installed-app verification passed with version `0.1.10`, build `11`, privacy strings absent, no network entitlements, hardened runtime metadata present, and no ScreenCaptureKit link. |
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
