# Release Checklist

Phases covered by this checklist:
- Phase 0–3 (Settings, Onboarding, Launch at Login, Diagnostics export)
- Phase 4–9.1 Pro features and Alpha RC hardening are now implemented behind explicit opt-in boundaries.

## Build

- Confirm project targets macOS 26.0+ only.
- Run the canonical commands (the scripts pick the active scheme and print the exact `xcodebuild` command before running):
  - `scripts/build_debug.sh`
  - `scripts/build_release.sh --dry-run`
  - `scripts/test.sh`
- Confirm unit tests pass (Swift Testing + XCTest). `scripts/test.sh` defaults to the focused hosted unit lane.
- Run `scripts/test.sh --ui` only when the local UI runner is explicitly part of the pass.
- Confirm scripts print the exact `xcodebuild` command before execution.
- Canonical local Alpha RC build commands use CI-style ad-hoc/no-account signing overrides. Unit tests use project local signing defaults so Xcode can launch the hosted test app:
  - `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`
  - `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests -enableCodeCoverage NO`
- Deprecated fallback scheme retained during transition:
  - `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests -enableCodeCoverage NO`

## Privacy

- Confirm Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Confirm Pro-only permissions are not reachable without explicit opt-in (Phase 4+ boundary).
- Review stored data and keep it minimal — only UserDefaults settings, in-memory diagnostics ring buffer (≤200 events), and exported diagnostics files the user explicitly chooses.
- Confirm the exported diagnostics bundle excludes screenshots, screen contents, personal file paths, and network data.
- Confirm onboarding content documents the no-permissions Basic Mode behavior.
- Confirm `SMAppService.mainApp.register()` is only ever called when the user explicitly enables "Launch at Login" — never auto-enabled.
- Run `scripts/verify_privacy_boundary.sh`.
- Confirm Diagnostics filtered export excludes screenshots, screen contents, live search text, selected item identity, personal file paths, and network data.
- Confirm `scripts/qa_network_watch.sh MenuBarDeclutter` shows no unexpected network connections during manual QA.

## App Behavior

- Confirm `LSUIElement` removes the Dock icon (accessory activation policy).
- Confirm status item appears and menu commands work.
- Confirm Settings and Diagnostics open from the status menu.
- Confirm Onboarding appears on first launch and is gated by `SettingsStore.hasCompletedOnboarding`.
- Confirm "Show Onboarding Again" in Settings → General re-presents it.
- Confirm Launch at Login registers and unregisters via `SMAppService.mainApp` without any other permission prompt.
- Confirm Launch at Login status is visible in Settings and Diagnostics.
- Confirm "Open Login Items Settings" opens the correct System Settings surface.
- Confirm Diagnostics export save panel writes a privacy-safe `.txt` or `.json` bundle to the user-chosen location.
- Confirm Diagnostics category/severity filters, copy selected event, and export filtered diagnostics work.
- Confirm "Pause Automation" / "Resume Automation" appears in the status menu and stops/starts smart trigger evaluation.
- Confirm Settings -> Advanced labels icon moving as experimental and shows the warning before enablement.
- Confirm Reset App Layout and Reset All Settings restore defaults without requiring relaunch.
- Confirm Quit works from the status menu.

## Distribution

- Revisit App Sandbox entitlements before distribution. Current local-alpha builds are intentionally non-sandboxed for opt-in Pro Accessibility Discovery; keep hardened runtime, no-network entitlements, and sensitive usage-string absence verified.
- Confirm hardened runtime metadata for local Release/dry-run artifacts where available.
- Do not require, configure, or assume Developer ID signing, notarization, or stapling for the current release stance.
- Treat `scripts/notarize_template.sh`, `docs/release/notarization-setup.md`, and `docs/release/notarization-runbook.md` as deferred templates until Developer ID distribution is explicitly requested.
- Confirm license audit remains clean (no GPL or source-available code from Ice, Thaw, SaneBar, or similar menu bar utilities).
- Complete `docs/release/alpha-rc-checklist.md`.
- Include `docs/release/alpha-rc-known-limitations.md` in release notes.

## macOS 26 matrix (manual QA)

See `docs/testing/manual-qa.md` for the full Phase 3 manual checklist, including:
- Light/dark, increased contrast, reduce transparency, transparent menu bar.
- External display tests.
- Launch at Login enable/disable.
- Quit/relaunch and restart-macOS cases where possible.

For Alpha RC, also complete:

- `docs/testing/privacy-qa.md`
- `docs/testing/alpha-rc-qa-matrix.md`
- `docs/testing/alpha-rc-qa-run-template.md`
- `docs/testing/known-risk-areas.md`
