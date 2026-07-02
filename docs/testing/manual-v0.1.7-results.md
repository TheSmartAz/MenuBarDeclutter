# Manual QA Results - v0.1.7

Date: 2026-07-02

Automated evidence after follow-up audit patches:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests` passed with 35 tests in 1 suite.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests` passed with 48 tests in 2 suites.
- `scripts/verify_privacy_boundary.sh` passed with privacy boundary source checks.
- Phase 20 source-boundary `rg` sweeps for forbidden capabilities and overclaim language found only verifier scripts, plan/history docs, or explicit exclusion/guardrail copy.
- Advanced settings and launch UI checks were stabilized during the final audit pass with named Advanced section identifiers and app-state waits before launch assertions.
- `scripts/qa_preflight.sh` passed after the final Phase 20 audit/UI stabilization fixes: build-for-testing succeeded, 538 app-unit tests in 75 suites passed, 16 UI tests passed, and privacy boundary source checks passed.
- `scripts/qa_dogfood_preflight.sh` passed after the final Phase 20 audit/UI stabilization fixes: main app build, fixture build, 125 focused tests in 12 suites, privacy boundary source checks, release artifact verification, and fixture launch completed.
- `scripts/build_release.sh --dry-run --install --verify-installed` passed for `v0.1.7`: archive/export/package completed, local install to `/Applications/MenuBarDeclutter.app` succeeded, and installed-app verification passed.
- Release artifact and installed-app verification reported expected dry-run warnings for the non-notarized build: `spctl` rejection and missing stapled ticket.

Manual QA run on 2026-07-02:

- Local display environment: one built-in Color LCD, 3456 x 2234 Retina, main display, mirroring off, internal connection.
- Launched the Debug build in isolated UI-testing mode with `--ui-testing --ui-testing-show-advanced`.
- Opened Advanced -> Workspaces Preview, enabled Workspaces Preview, Function Bar Preview, Set Builder Preview, and Info Strip Preview.
- Enabled Info Strip for the active Default workspace, confirmed seven selected local tile providers, and saved the workspace Info Strip config.
- Opened Info Strip Preview and observed the app-owned floating `Info Strip Preview` panel render a Battery tile with Function Bar, Next, and Close controls.
- Waited past the configured 8 second rotation interval and observed the tile advance to the recovery status tile.
- The UI-testing sandbox persisted the active workspace Info Strip config under `/var/folders/w1/vw_ntlk55wj37zd6_s715wb80000gn/T/MenuBarDeclutterUITests/MenuBarDeclutter/workspaces/workspaces.json`; normal user settings were not used.

Manual QA still required before release:

- External multi-display placement behavior with an attached secondary display.
- Physical notch/edge placement review on release hardware.
