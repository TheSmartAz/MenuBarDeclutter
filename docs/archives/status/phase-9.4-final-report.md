# Phase 9.4 Final Report

Status: implemented stability/gating hardening; automated preflights pass; hands-on system dogfood remains required.

## Completed

- Dogfood triage, bug index, and risk board created.
- Basic Mode has no confirmed automated S0/S1 blocker in reviewed evidence.
- v0.1-safe defaults implemented.
- Settings migration service added with unit tests.
- Launch at Login clarity improved with current bundle path and installed-app warning.
- Diagnostics now show bundle path and `/Applications` status.
- Emergency recovery menu action added: Reveal All + Reset Separators.
- Icon Moving remains disabled by default and experimental.
- Automation is paused by default; trigger debounce and URL command throttling remain in place.
- Release docs distinguish blockers from accepted limitations.

## Remaining Manual Gates

- Real Basic Mode menu bar placement and collapse/expand.
- Installed-app Launch at Login.
- Accessibility grant/revoke.
- Safe Mode crash-marker and option-launch flows.
- External display/notch/sleep-wake/Spaces.
- Interactive network observation.

## Validation Commands

- `xcodebuild -list`: PASS.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet`: PASS.
- Full app/unit/UI tests via `scripts/qa_preflight.sh`: PASS; unit tests passed 215 tests in 37 suites, UI tests passed 7 tests.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`: PASS with expected non-notarized warnings.
- `scripts/qa_dogfood_preflight.sh`: PASS; main app build, fixture build, selected dogfood/unit tests, and privacy boundary passed.

Recommendation: Phase 9.4 is complete for automated stability/gating hardening. v0.1 remains blocked for public release by notarization credentials and manual system-state QA, not by known automated Basic Mode or privacy failures.
