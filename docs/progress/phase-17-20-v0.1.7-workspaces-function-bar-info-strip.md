# Phase 17-20 Progress: v0.1.4-v0.1.7 Workspaces Track

Status: implemented in this checkout.

## Completed

- Added Workspace data models, validation, persistence, repair, and backups.
- Added app-owned Function Bar and Info Strip preview panels.
- Added Set Builder draft editing for Workspaces and Function Bar items.
- Added settings defaults, import/export support, migration snapshots, and App Support paths.
- Added Command Center actions for Workspace switching, Function Bar, and Info Strip.
- Added Advanced -> Workspaces Preview settings entry point.
- Added status menu Advanced entries for Workspaces Preview, Function Bar Preview, and Info Strip Preview.
- Added targeted pure-logic tests.
- Repaired Phase 20 audit gaps around Info Strip selected-provider availability diagnostics and Pro Discovery labeling in the Set Builder tile library.
- Repaired Phase 20 rotation clamping to the documented `3...300` second bound and stabilized the full UI preflight around Advanced settings and launch-state waits.

## Out Of Scope

- No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network calls, or private APIs.
- No real menu bar item movement from Set Builder.
- No Function Bar runtime replacement for Basic Mode hiding.
- No online weather, news, media, calendar, reminders, or account tiles.

## Verification

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests` passed after the Phase 20 audit fixes with 48 tests in 2 suites.
- `scripts/verify_privacy_boundary.sh` passed after the Phase 20 audit fixes with privacy boundary source checks.
- Phase 20 source-boundary `rg` sweeps for forbidden capabilities and overclaim language found only verifier scripts, plan/history docs, or explicit exclusion/guardrail copy.
- `scripts/qa_preflight.sh` passed after the Phase 20 audit/UI stabilization fixes with 538 app-unit tests in 75 suites, 16 UI tests, and privacy boundary source checks.
- `scripts/qa_dogfood_preflight.sh` passed after the Phase 20 audit/UI stabilization fixes with 125 focused tests in 12 suites, privacy boundary source checks, release artifact verification, and fixture launch.
- `scripts/build_release.sh --dry-run --install --verify-installed` passed for `v0.1.7`, including local install verification. Non-notarized `spctl` and missing stapled-ticket warnings are expected for dry-run artifacts.
