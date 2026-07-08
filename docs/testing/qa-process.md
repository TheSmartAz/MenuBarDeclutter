# QA Process

This project uses risk-based QA lanes. The full QA catalog exists so release and dogfood claims can be checked, but every row is not required for every code change.

Allowed manual results are `PASS`, `FAIL`, `BLOCKED`, `NOT TESTED`, and `PARTIAL`.

## Source Of Truth

- This file decides which QA lane applies.
- `docs/testing/macos26-test-matrix.md` is the broad coverage catalog for real macOS validation.
- `docs/testing/v0.1-regression-suite.md` is the release execution checklist for stable v0.1 claims.
- `docs/testing/dogfood/` contains conditional dogfood gates for daily-use and feature-specific validation.
- `docs/release/v0.1.10-release-runbook.md` is the current release-candidate command sequence.
- Phase-specific manual QA files are historical unless the current release checklist links them.

## Lane 1: Patch

Use this lane for ordinary localized changes that do not affect permissions, release packaging, installed-app behavior, menu bar system behavior, or public claims.

Steps:

1. Run focused unit or UI tests for the changed area when available.
   For pure logic covered by `MenuBarDeclutterLogicTests`, use:

   ```sh
   scripts/run_logic_tests.sh
   ```

   This lane builds the logic-test bundle and runs it directly with
   `xcrun xctest`, avoiding local app-hosted runner attachment failures.
2. For code changes, run one canonical test command before handoff:

   ```sh
   xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
   ```

   `scripts/test.sh` is acceptable when the scheme fallback behavior is useful.
   If the local Xcode runner fails before tests attach, record the infra failure
   and include passing `scripts/run_logic_tests.sh` evidence for pure logic changes.

   Known local runner symptom on macOS 26/Xcode 17: `xcodebuild test` or
   `xcodebuild test-without-building` can hang before materializing test workers
   and then require an external timeout. In that case, treat the Xcode runner as
   blocked only after `xcodebuild build-for-testing` succeeds and direct
   `xcrun xctest` through `scripts/run_logic_tests.sh` passes.
3. For documentation-only changes, run a lightweight validation such as:

   ```sh
   git diff --check
   ```

Patch lane evidence should name the command and result. Manual QA is not required unless the change alters user-visible system behavior.

## Lane 2: Risk

Use this lane when a change touches any of these areas:

- AppKit status items, separator lengths, menu bar geometry, auto-rehide, hover reveal, hotkeys, or recovery.
- Settings, onboarding, diagnostics export, health reports, or privacy-facing copy.
- Pro Mode, Accessibility discovery, Find Icon, Second Bar, icon moving, profiles, triggers, or URL automation.
- Info.plist, entitlements, signing, release scripts, installed-app behavior, or Launch at Login.
- UI layout, navigation, visual design, or screenshot-visible surfaces.

Steps:

1. Run focused tests for the changed area.
2. Run:

   ```sh
   scripts/qa_preflight.sh
   ```

   This already records system/toolchain/git context, lists schemes, builds for testing, runs unit/UI tests separately, and runs the source privacy verifier.
3. If the change touches privacy, permissions, diagnostics, networking, Info.plist, entitlements, Pro Mode, or release artifacts, run:

   ```sh
   scripts/verify_privacy_boundary.sh
   ```

   For built or installed apps, pass `APP_PATH`.
4. If the change is visual, run screenshot QA or UI smoke coverage:

   ```sh
   scripts/qa_capture_ui_screenshots.sh --build --focused-only
   ```

5. Run only the relevant manual QA rows from the coverage catalog. Do not run unrelated hardware, dogfood, or release rows just because they exist.

## Lane 3: Release Candidate

Use this lane for ship candidates, public-claim changes, or final validation before tagging/releasing.

Steps:

1. Follow the current release runbook:

   ```sh
   docs/release/v0.1.10-release-runbook.md
   ```

2. Run or explicitly record exceptions for `docs/testing/v0.1-regression-suite.md`.
3. Install and verify the exported app when making installed-app claims:

   ```sh
   scripts/build_release.sh --dry-run --install --verify-installed
   scripts/qa_installed_app_smoke.sh
   ```

4. Run network observation on the installed app:

   ```sh
   scripts/qa_network_watch.sh --installed
   ```

5. Record manual results in the current release result file with date, environment, app build, exact commands, and remaining blockers.

Developer ID export, notarization, stapling, and public distribution remain out of scope until explicitly requested.

## Conditional Gates

| Step | Required When |
| --- | --- |
| Focused tests | Every code change with relevant coverage |
| Full `xcodebuild test` or `scripts/test.sh` | Before handoff for app code changes |
| `scripts/qa_preflight.sh` | Risk lane or release candidate |
| `scripts/verify_privacy_boundary.sh` | Privacy, permissions, diagnostics, Info.plist, entitlements, Pro Mode, release, or network-adjacent changes |
| Screenshot QA | UI, layout, visual design, panels, Settings, onboarding, or status menu changes |
| Dogfood Gate A | Basic Mode stability or daily-use claims |
| Dogfood Gate B | Pro read-only Accessibility discovery claims |
| Dogfood Gate C | Pro assisted features, profiles, triggers, Second Bar, or URL automation claims |
| Dogfood Gate D | Icon Moving experimental claims only |
| Dogfood Gate E | Installed-app release claims |
| External display/notch/sleep-wake/manual Command-drag | Display/menu bar changes or release claims that depend on real hardware behavior |
| Launch at Login logout/restart | Installed-app release claims only |
| Notarization/stapling | Only after Developer ID distribution enters scope |

## Duplication Rules

- Do not rerun `xcodebuild -list`, `scripts/test.sh`, and `scripts/qa_preflight.sh`
  solely to collect duplicate evidence. `qa_preflight.sh` already includes scheme
  listing and unit/UI test lanes.
- Do not repeat privacy checks manually when `scripts/verify_privacy_boundary.sh`
  proves the static/source/bundle invariant. Manual privacy QA should focus on
  runtime prompts and user-facing degraded states.
- Treat `macos26-test-matrix.md` as a catalog, not a mandatory per-change checklist.
- Treat `v0.1-regression-suite.md` as a release checklist, not a patch checklist.

## Non-Negotiable Boundaries

- Basic Mode must remain fully usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Pro Mode must remain explicit opt-in and degrade gracefully when permissions are missing or revoked.
- Icon Moving remains Experimental, disabled by default, user-triggered only, and must not block Basic Mode.
- Manual QA blockers must be recorded rather than hidden. Hardware-unavailable rows may be `BLOCKED` if the release claim is scoped accordingly.
