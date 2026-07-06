# Manual QA: Pro Second Bar Compact Strip

Last updated: 2026-07-06

## Scope

This checklist covers the Pro compact Second Bar strip. These behaviors require real macOS menu bar state, Accessibility, Screen Recording, and third-party status items, so they cannot be fully validated by unit tests.

## 2026-07-06 Automated Evidence

| Area | Result | Notes |
| --- | --- | --- |
| Latest installed app | PASS | `scripts/build_release.sh --dry-run --install --verify-installed` refreshed `/Applications/MenuBarDeclutter.app` at 2026-07-06 05:53 PDT after primary-click opt-in and verified `0.1.10` build `11`. |
| Installed privacy and network boundary | PASS | `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app` passed installed privacy checks, observed no network sockets, verified URL command reuse with PID `52086`, and verified one-shot Safe Mode flag consumption with normal relaunch PID `52901`. |
| Settings setup visibility | PASS | Screenshot QA captured Privacy and Second Bar settings after the setup checklist was added; the latest full settings run is `docs/testing/screenshot-qa/2026-07-06_073635/`. |
| Compact strip UI-test hook compiles | PASS | Added `--ui-testing-show-compact-second-bar` with seeded rendered icons and `testCompactSecondBarShowsReadyHiddenItems`; `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/ui-compact-strip CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO -quiet` passed. |
| App Intent readiness gate | PASS | `showSecondBarAppIntentUsesFullReadinessGate` verifies the Shortcuts/App Intent entry point blocks before handler execution when Optional Pro, Accurate Icons, or Screen Recording are missing, and runs only when the full Second Bar readiness chain is satisfied. |
| URL automation readiness gate | PASS | `secondBarURLUsesFullReadinessGate` verifies `menubardeclutter://second-bar` blocks before handler execution when Accurate Icons or Screen Recording are missing, and runs only when the full Second Bar readiness chain is satisfied. |
| Direct activation matrix logging | PASS | `directActivationResultsMapToMatrixOutcomes` verifies direct activation results map to the QA matrix `matrixResult` values, and runtime diagnostics now log `matrixResult` with the existing activation metadata. |
| Direct activation matrix helper | PASS | `qa_second_bar_activation_matrix.sh` converts sanitized diagnostics JSON activation logs into markdown matrix rows so hands-on testers do not need to copy `targetID`, `targetZone`, `matrixResult`, `visitedElementCount`, `axError`, and `message` manually. |
| Primary-click opt-in gate | PASS | `primaryClickRequiresExplicitSecondBarOptInBeforeUsingCompactStrip` verifies Pro readiness alone does not reroute the status item click; compact strip routing requires `Use menu bar icon for Second Bar`, and revoked readiness shows requirements only after that opt-in. |
| Activation failure retry state | PASS | `activationFailureFeedbackRetainsRetryTarget` verifies failed compact-strip activation feedback keeps the failed snapshot so the strip can show a `Retry` control instead of closing or losing the target. |
| Safe Mode primary-click suppression | PASS | `primaryClickRoutesSafeModeToInlineEvenWhenReadyAndOptedIn` verifies Safe Mode suppresses compact-strip primary-click routing even when Pro, readiness, and explicit opt-in are all enabled. |
| Compact strip scan state | PASS | `compactStripPlanReportsNoScanWhenNoScanTimeIsAvailable` and `compactStripPlanReportsStaleScanWhenLastScanIsOld` verify the strip distinguishes no scan, stale scan, and fresh scan instead of treating all empty states as no hidden icons. |
| Compact strip screenshot QA | PASS | `scripts/qa_capture_ui_screenshots.sh --build --focused-only --output-dir docs/testing/screenshot-qa/2026-07-06_secondbar-compact-strip` captured 20 surfaces with 0 skipped and 0 failed. Manifest row `32-compact-second-bar` captured a `166x42` `Second Bar Compact Strip` window using full readiness gates, primary-click opt-in, seeded menu bar items, and seeded rendered icons. |
| Warm-up diagnostics | PASS | Live diagnostics now reports `Icon Warm-up Running` and `Last Icon Warm-up` for Second Bar, so hands-on Accurate Icons warm-up runs can verify completion without inspecting private thumbnails. |
| Compact strip UI-test execution | BLOCKED-INFRA | Focused `xcodebuild test-without-building` for `testCompactSecondBarShowsReadyHiddenItems` did not materialize workers and surfaced the macOS `XCTest is trying to Enable UI Automation` authorization prompt before app assertions. |
| Real permission prompts | NOT TESTED | Accessibility and Screen Recording prompt behavior requires explicit hands-on interaction with macOS Privacy & Security panes. |
| Compact strip ready-state behavior | NOT TESTED | Accurate Icons warm-up, real third-party item inclusion, notch-edge placement, and direct activation require live menu bar items and granted permissions. |

## Preconditions

- Build and launch `MenuBarDeclutter`.
- Have at least three third-party menu bar apps installed and visible in the menu bar.
- Keep one third-party menu bar item in the hidden zone.
- Keep one item in the always-hidden zone, if Always Hidden is enabled.
- Enable Optional Pro only for Pro test cases.
- Enable Accessibility Discovery only for Pro test cases.
- Enable Accurate Icons only for ready-state test cases.

## Pro Setup Flow

1. Open Settings -> Privacy.
2. Confirm `Pro Second Bar Setup` is visible near the top of the page.
3. Starting from Basic Mode, confirm only `Optional Pro` is actionable and later steps are waiting.
4. Click `Enable Pro` and confirm no macOS permission prompt appears.
5. Click `Enable Discovery` and confirm no macOS permission prompt appears.
6. Click `Request Permission` for Accessibility and confirm the macOS Accessibility permission flow is user-initiated.
7. Enable Accurate Icons and confirm no Screen Recording prompt appears until its `Request Permission` button is clicked.
8. Click `Request Permission` for Screen Recording and confirm the macOS Screen Recording flow is user-initiated.
9. Confirm the setup checklist reports ready only when Optional Pro, Accessibility Discovery, Accessibility, Accurate Icons, and Screen Recording are all ready.
10. Open Settings -> Second Bar and confirm the same setup checklist and readiness state are shown first on the page.
11. Confirm `Use menu bar icon for Second Bar` is available only after setup is ready.
12. Click `Warm Up Icons` after the checklist is ready.
13. Confirm hidden items may briefly reveal, thumbnails refresh, and the previous visibility state is restored.
14. Open Settings -> Diagnostics and confirm Second Bar live status shows `Icon Warm-up Running` returning to `No` and `Last Icon Warm-up` reporting the refreshed thumbnail count.

## Basic Mode

1. Reset to Basic Mode with Optional Pro disabled.
2. Confirm no Accessibility prompt appears.
3. Confirm no Screen Recording prompt appears.
4. Left-click the MenuBarDeclutter status item.
5. Confirm the existing inline hide/show behavior still runs.
6. Confirm no compact strip is shown.
7. Confirm `Use menu bar icon for Second Bar` is off.

## Pro Readiness Gate

1. Complete Pro Second Bar setup until the checklist is ready.
2. Leave `Use menu bar icon for Second Bar` off.
3. Left-click the MenuBarDeclutter status item.
4. Confirm the existing inline hide/show behavior still runs and no compact strip appears.
5. Enable `Use menu bar icon for Second Bar`.
6. Disable Accessibility Discovery.
7. Left-click the MenuBarDeclutter status item.
8. Confirm a compact requirements strip appears near the status item.
9. Confirm it names Accessibility Discovery as missing.
10. Enable Accessibility Discovery but deny or revoke Accessibility permission.
11. Left-click again and confirm the requirements strip names Accessibility permission.
12. Grant Accessibility, disable Accurate Icons, and left-click again.
13. Confirm Accurate Icons is named as missing.
14. Enable Accurate Icons but revoke Screen Recording.
15. Confirm Screen Recording is named as missing.
16. Confirm the status menu `Show Second Bar` command is blocked by the same missing gate.

## Compact Strip Layout

1. Grant Accessibility and Screen Recording, then prepare Accurate Icons.
2. Enable `Use menu bar icon for Second Bar`.
3. Move the MenuBarDeclutter status item so there is enough space to the right edge of the screen.
4. Left-click the status item.
5. Confirm the strip starts under the status item and extends toward the right screen edge.
6. Move the status item close to the right edge so the status-item-to-edge region is too narrow.
7. Left-click again.
8. Confirm the strip falls back to the notch-left-edge-to-right-edge region.
9. Confirm the strip is one row only.
10. Confirm visible content uses icon-only buttons with tooltips/accessibility labels.
11. Confirm the strip repositions or closes cleanly after display changes, Space changes, and wake.

## Item Inclusion

1. Confirm Hidden-zone items with prepared Accurate Icons appear in the compact strip.
2. Confirm Visible-zone items do not appear.
3. Confirm Always Hidden items do not appear.
4. Confirm the MenuBarDeclutter status item does not appear.
5. Add more Hidden-zone items than fit in one row.
6. Confirm extra ready items are represented by `+N`.
7. Confirm hidden items that still need Accurate Icons contribute to the additional count.
8. Clear or block scanning and confirm an empty strip says `No scan yet` instead of `No hidden icons`.
9. Let the latest scan become stale and confirm ready icons remain visible with a `Scan stale` badge.
10. Click the Manage/Search control and confirm the full Second Bar panel opens.

## Direct Activation

1. Open the compact strip with a Hidden third-party item ready.
2. Click a third-party icon in the compact strip.
3. Confirm the third-party menu opens or performs the same action as clicking the real menu bar item.
4. Confirm the compact strip closes on successful activation.
5. Test an item whose owner app has quit or whose AX element changed since the last scan.
6. Confirm activation failure leaves the strip open and shows a `Retry` action.
7. Click `Retry` and confirm it attempts the same target again.
8. Confirm failure is logged in diagnostics without revealing private item names beyond stable diagnostic IDs.
9. Confirm the `Second Bar activation result` log includes `matrixResult`, `targetID`, `targetZone`, `visitedElementCount`, `axError`, and `message`.
10. Export diagnostics as JSON and run `scripts/qa_second_bar_activation_matrix.sh` to generate rows.
11. Record reviewed rows in `docs/testing/pro-second-bar-direct-activation-matrix.md`.

## Regression Checks

1. Right-click the status item and confirm the status menu still opens.
2. Option-click the status item and confirm reveal-all behavior still works when enabled.
3. Confirm `Hide Second Bar` can close either the full panel or compact strip.
4. Confirm Basic Mode remains usable after revoking all Pro permissions.
5. Confirm no network access is required for compact strip behavior.
6. Disable Pro and confirm `Use menu bar icon for Second Bar` is cleared.
7. Launch in Safe Mode with `Use menu bar icon for Second Bar` previously enabled and confirm left-click falls back to Basic inline hide/show instead of opening compact strip.
