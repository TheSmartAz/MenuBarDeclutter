# Phase 20 Progress - v0.1.7 Info Strip MVP

Date: 2026-07-02

Implemented in the current worktree. Audit rerun on 2026-07-02 and Phase 20 gaps closed.

Evidence:

- `MenuBar-Manager/InfoStrip/` contains models, providers, rotation runtime, placement, controller, views, and diagnostics.
- Required local tile providers are registered.
- Info Strip Preview and auto-show settings exist, with preview off by default.
- Per-Workspace Info Strip config exists and defaults off.
- `WorkspaceDisplayCoordinator` coordinates Function Bar and Info Strip show/hide paths.
- Hover-to-Function Bar and idle-to-Info Strip are gated by explicit global/per-Workspace settings.
- Set Builder can configure selected Info Strip tile providers for a Workspace.
- Workspaces Preview exposes Info Strip Preview controls and the Phase 20 product-boundary copy that Info Strip is app-owned UI, not a system menu bar replacement.
- Status menu preview actions are gated by Workspaces Preview plus the child preview setting, with visible panels retaining a hide escape hatch.
- Failed Info Strip show attempts keep display state unavailable instead of reporting a visible strip.
- Workspace validation clamps Info Strip rotation intervals to the Phase 20 `3...300` second bound.
- Info Strip diagnostics count availability against selected tile providers, so Pro Discovery-only selected tiles report unavailable instead of being hidden by unrelated available registry tiles.
- Set Builder labels Pro Discovery-only Info Strip tiles as requiring Pro while leaving them selectable for local preview configuration.
- Current-facing README and roadmap language points at `v0.1.7`.

Audit fixes closed:

- Repaired the Info Strip rotation validation upper bound from `120` to `300` seconds and renamed the regression test to Phase 20.
- Added Workspaces Preview source checks for the Info Strip settings controls and boundary copy.
- Tightened Status Bar advanced menu relevance so Info Strip and Function Bar preview commands do not appear from child feature flags alone.
- Added coverage for the failed-show display-state path.
- Stabilized Arrange and Privacy UI test accessors around named scroll views/action rows discovered during the audit rerun.
- Stabilized Advanced and launch UI coverage by terminating stale app instances, waiting for the app state transition, and exposing stable Advanced section identifiers for the full preflight suite.
- Repaired selected-provider availability diagnostics for Info Strip tiles gated by Pro Discovery.
- Added Set Builder library copy/badges that make Pro Discovery requirements visible for New Items and Stale Scan Info Strip tiles.

Verification:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests` passed after the final audit fixes: 35 tests in 1 suite.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests` passed after the final audit fixes: 48 tests in 2 suites.
- `scripts/verify_privacy_boundary.sh` passed after the final audit fixes: privacy boundary source checks passed, with built-app checks skipped because `APP_PATH` was not set.
- Phase 20 source-boundary `rg` sweeps for forbidden capabilities and overclaim language were re-run; hits were verifier scripts, plan/history docs, or explicit exclusion/guardrail copy, not app code adding ScreenCaptureKit, Screen Recording, network clients, telemetry, physical workspace switching, or Info Strip icon movement.
- `scripts/qa_preflight.sh` passed after the final audit/UI stabilization fixes: build-for-testing succeeded, 538 app-unit tests in 75 suites passed, 16 UI tests passed, and privacy boundary source checks passed. Built-app privacy checks were skipped in this script because `APP_PATH` was not set.
- `scripts/qa_dogfood_preflight.sh` passed after the final audit/UI stabilization fixes: main app build, fixture build, 125 focused tests in 12 suites, privacy boundary source checks, release artifact verification, and fixture launch completed.
- `scripts/build_release.sh --dry-run --install --verify-installed` passed after the final audit/UI stabilization fixes: archive/export/package completed for `MenuBarDeclutter-v0.1.7-alpha.zip` and `MenuBarDeclutter-v0.1.7.zip`, local install to `/Applications/MenuBarDeclutter.app` succeeded, and installed-app verification passed.
- Release artifact and installed-app verification reported expected dry-run warnings for the non-notarized build: `spctl` rejection and missing stapled ticket.
