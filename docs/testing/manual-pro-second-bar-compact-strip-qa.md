# Manual QA: Pro Second Bar Compact Strip

Last updated: 2026-07-07

## Scope

This checklist covers the Pro compact Second Bar strip. These behaviors require real macOS menu bar state, Accessibility, Screen Recording, and third-party status items, so they cannot be fully validated by unit tests.

## 2026-07-07 Automated And Live Evidence

| Area | Result | Notes |
| --- | --- | --- |
| Latest installed app | PASS | `scripts/build_release.sh --dry-run --local-development-signing --install --verify-installed` refreshed `/Applications/MenuBarDeclutter.app` after the compact strip top-origin frame, fixed-placement, UI-test seed, and Rehide poll-interval updates and verified `0.1.10` build `11`; installed Apple Development-signed CDHash `8539bb7dff6bd994edcef7ed09603a86b337f94b`. |
| Installed privacy and network boundary | PASS | `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app` passed installed privacy checks, observed no network sockets for PID `46604`, verified URL command reuse with PID `46604`, verified one-shot Safe Mode flag consumption, and verified normal relaunch PID `47274`. |
| Settings setup visibility | PASS | Screenshot QA captured Privacy and Second Bar settings after the setup checklist was added; the latest full settings run is `docs/testing/screenshot-qa/2026-07-06_073635/`. |
| Compact strip UI-test hook compiles | PASS | Added `--ui-testing-show-compact-second-bar` with seeded rendered icons and `testCompactSecondBarShowsReadyHiddenItems`; `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/ui-compact-strip CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO -quiet` passed. |
| App Intent readiness gate | PASS | `showSecondBarAppIntentUsesFullReadinessGate` verifies the Shortcuts/App Intent entry point blocks before handler execution when Optional Pro, Accurate Icons, or Screen Recording are missing, and runs only when the full Second Bar readiness chain is satisfied. |
| URL automation readiness gate | PASS | `secondBarURLUsesFullReadinessGate` verifies `menubardeclutter://second-bar` blocks before handler execution when Accurate Icons or Screen Recording are missing, and runs only when the full Second Bar readiness chain is satisfied. |
| Direct activation matrix logging | PASS | `directActivationResultsMapToMatrixOutcomes` verifies direct activation results map to the QA matrix `matrixResult` values, and runtime diagnostics now log `matrixResult` with the existing activation metadata. Direct activation now attempts public `AXPress`, public `AXShowMenu`, then a guarded CGEvent click fallback for menu bar frames that reject AX actions. |
| Direct activation matrix helper | PASS | `qa_second_bar_activation_matrix.sh` converts sanitized diagnostics JSON activation logs into markdown matrix rows so hands-on testers do not need to copy `targetID`, `targetZone`, `matrixResult`, `visitedElementCount`, `axError`, and `message` manually. |
| Manual gate audit helper | PASS | `qa_second_bar_manual_gate_audit.sh` checks a hands-on diagnostics JSON export for ready Second Bar gates, Accurate Icons warm-up, compact-strip runtime evidence, direct activation PASS coverage, optional notch/failure coverage, and optional matrix-row output. `secondBarManualGateAuditChecksReadinessRuntimeAndActivationEvidence` covers passing diagnostics and stale warm-up rejection with a sanitized fixture. |
| Sign-off audit helper | PASS | `qa_second_bar_signoff_audit.sh` aggregates the manual QA evidence table, Gate C dogfood Second Bar rows, direct activation matrix coverage, and compact strip screenshot manifest. It intentionally fails until real Gate C dogfood rows and reviewed direct activation matrix rows are complete; `secondBarSignoffAuditAggregatesEvidenceAndFailsMissingDogfood` covers passing and failing fixture evidence. |
| Primary-click opt-in gate | PASS | `primaryClickRequiresExplicitSecondBarOptInBeforeUsingCompactStrip` verifies Pro readiness alone does not reroute the status item click; compact strip routing requires `Use menu bar icon for Second Bar`, and revoked readiness shows requirements only after that opt-in. |
| Activation failure retry state | PASS | `activationFailureFeedbackRetainsRetryTarget` verifies failed compact-strip activation feedback keeps the failed snapshot so the strip can show a `Retry` control instead of closing or losing the target. |
| Safe Mode primary-click suppression | PASS | `primaryClickRoutesSafeModeToInlineEvenWhenReadyAndOptedIn` verifies Safe Mode suppresses compact-strip primary-click routing even when Pro, readiness, and explicit opt-in are all enabled. |
| Compact strip item inclusion | PASS | `compactStripIncludesHiddenItemsEvenWhenAccurateIconsAreNotReady` verifies Hidden-zone items stay visible even when a specific rendered thumbnail is missing, `compactStripAdditionalCountTracksOverflowNotMissingAccurateIcons` verifies `+N` counts only one-line overflow, and `compactStripAcceptsTopOriginRightSideMenuBarFrames` covers the real AX top-origin frame shape observed from installed status items. |
| Compact strip scan state | PASS | `compactStripPlanReportsNoScanWhenNoScanTimeIsAvailable` and `compactStripPlanReportsStaleScanWhenLastScanIsOld` verify the strip distinguishes no scan, stale scan, and fresh scan instead of treating all empty states as no hidden icons. |
| Compact strip diagnostics export | PASS | Diagnostics live status and export now record the last compact strip visible count, overflow count, fallback-icon count, scan state, whether the last compact placement used notch avoidance, and the last direct-activation result/matrix/zone/visited-count/AX-error. `applyingSecondBarCompactStripPlanUpdatesPrivacySafeDiagnostics`, `applyingSecondBarDirectActivationUpdatesPrivacySafeDiagnostics`, and `jsonExportCanIncludeSecondBarRuntimeDiagnostics` cover those values without item names or image data. |
| Compact strip screenshot QA | PASS | `scripts/qa_capture_ui_screenshots.sh --build --focused-only --output-dir docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2` captured 24 surfaces with 0 skipped and 0 failed. Manifest rows `32-compact-second-bar` and `33-compact-second-bar-fallback-icons` captured `166x42` ready/fallback `Second Bar Compact Strip` windows, and rows `34-compact-second-bar-accessibility-required`, `35-compact-second-bar-accurate-icons-required`, and `36-compact-second-bar-screen-recording-required` captured compact requirements strips. The fallback row used only a partial rendered icon seed, and the Accessibility requirements row simulates permission revocation after startup so startup health does not reset the explicit primary-click opt-in. |
| Warm-up diagnostics | PASS | Live diagnostics now reports `Icon Warm-up Running` and `Last Icon Warm-up` for Second Bar, so hands-on Accurate Icons warm-up runs can verify completion without inspecting private thumbnails. |
| Readiness diagnostics export | PASS | Diagnostics exports can include a privacy-safe `secondBarReadiness` block with readiness state, title/message, entitlement, Accessibility Discovery, Accessibility permission, Accurate Icons, Screen Recording, primary-click route, and Safe Mode state. `jsonExportCanIncludeSecondBarReadinessDiagnostics` covers JSON and text output. |
| Screen Recording recovery guidance | PASS | Installed Privacy UI now shows the manual recovery instruction when Screen Recording remains `Not Granted`: if MenuBarDeclutter is not listed in Privacy & Security -> Screen & System Audio Recording, use Add and select `/Applications/MenuBarDeclutter.app`. `ScreenCapturePermissionServiceTests` covers the instruction and failed-request state. |
| Permission preflight helper | PASS | `scripts/qa_second_bar_permission_preflight.sh --prepare-local-gates` passed against the refreshed installed app with CDHash `8539bb7dff6bd994edcef7ed09603a86b337f94b`; app-observed Accessibility and Screen Recording are both `granted`, Accurate Icons is enabled, Second Bar is enabled, and primary-click compact strip opt-in is enabled. |
| Missing permission recovery behavior | PASS | Startup health recovery no longer disables Optional Pro solely because Accessibility is denied; `missingProPermissionRefreshesStatusWithoutDisablingProMode` verifies the issue refreshes permission status instead. After installing the fix, `scripts/qa_second_bar_permission_preflight.sh --prepare-local-gates` kept Optional Pro, Accessibility Discovery, Accurate Icons, Second Bar, and primary-click compact strip opt-in enabled after relaunch. |
| Compact strip UI-test execution | PASS | `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBarDeclutterUITests/testCompactSecondBarShowsReadyHiddenItems -quiet` passed after updating the seeded frames to current top-origin/right-side menu bar geometry and asserting compact item identity through the AX value exposed by the icon buttons. A full-suite rerun still exited 65 with unrelated UI page assertion failures and one compact root flake, while the focused compact UI test passed again immediately afterward. |
| Real permission prompts | PASS | User completed the required macOS privacy authorization flow; the installed app now reports app-observed Accessibility `granted` and Screen Recording `granted` through `scripts/qa_second_bar_permission_preflight.sh`. |
| Compact strip ready-state behavior | PASS | 2026-07-07 live dogfood passed after Accessibility and Screen Recording were granted. The refreshed installed app opened a fixed-width one-line `Second Bar Compact Strip` at `597x34` from the real MenuBarDeclutter status item; screenshot evidence is `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/fixed-compact-strip-after-refresh.png`. Diagnostics export `fixed-after-status-click.json` recorded `lastCompactVisibleItemCount = 2`, `lastCompactScanState = Fresh`, `lastCompactFallbackIconCount = 0`, and `lastIconWarmUpResult = Refreshed 14 thumbnail(s)`. Clicking the two visible compact strip icons (`Codex Computer Use` and `Mole`) recorded `lastActivationMatrixResult = PASS`, `lastActivationResult = success`, `lastActivationTargetZone = hidden`, and `lastActivationVisitedElementCount = 2`; matching diagnostics are `after-codex-computer-use-click.json` and `after-mole-click.json`. The final installed build exported `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/final-installed-after-compact-url.json` with `lastCompactVisibleItemCount = 1`, `lastCompactScanState = Fresh`, `lastCompactFallbackIconCount = 0`, `lastCompactAvoidedNotch = true`, placement `976 x 34`, and `lastIconWarmUpResult = Refreshed 15 thumbnail(s)`. Earlier fixture-assisted, third-party WeChat/Magnet/Surge, stale/relaunch, failure-feedback, nil-anchor notch fallback, and controlled permission-revoked evidence remain under `build/qa-artifacts/second-bar-live/` and `docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2/`. |

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
15. Export diagnostics as JSON or text and confirm the Second Bar readiness section records the current readiness state, missing gate, primary-click route, and Safe Mode state without screenshot or icon identity data.

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
5. Confirm the strip appears immediately from the last scan/cache, without waiting for a fresh scan or Accurate Icons warm-up.
6. Confirm the strip starts under the status item and extends toward the right screen edge.
7. Confirm any subsequent scan or Accurate Icons refresh updates the already-visible strip rather than delaying initial presentation.
8. Move the status item close to the right edge so the status-item-to-edge region is too narrow.
9. Left-click again.
10. Confirm the strip falls back to the notch-left-edge-to-right-edge region.
11. Confirm the strip is one row only and uses menu-bar-like system material rather than the larger floating management-panel chrome.
12. Confirm visible content uses icon-only buttons with tooltips/accessibility labels.
13. Confirm each icon slot visually matches the original menu bar item size, including wider text/status items where present.
14. Open Settings -> Diagnostics and confirm `Last Compact Avoided Notch` reports `Yes` after the notch fallback placement.
15. Confirm the strip repositions or closes cleanly after display changes, Space changes, and wake.

## Item Inclusion

1. Confirm Hidden-zone items appear in the compact strip.
2. Confirm Visible-zone items do not appear.
3. Confirm Always Hidden items do not appear.
4. Confirm the MenuBarDeclutter status item does not appear.
5. Confirm likely system items such as Wi-Fi, Control Center, Battery, and Clock do not appear.
6. On a notched display, confirm Hidden-zone items left of the notch do not appear; only Hidden-zone app items to the right of the notch appear.
7. On a non-notched display, confirm Hidden-zone candidates from the left app-menu half do not appear.
8. Add more Hidden-zone items than fit in one row.
9. Confirm extra Hidden-zone items that do not fit are represented by `+N`.
10. Confirm a Hidden-zone item without a prepared rendered thumbnail remains in the strip with an app or placeholder fallback icon and does not inflate `+N` unless it is actually overflow.
11. Open Settings -> Diagnostics and confirm `Last Compact Visible`, `Last Compact Overflow`, `Last Compact Fallback Icons`, and `Last Compact Scan` match the strip.
12. Export diagnostics as JSON or text and confirm the `Second Bar Runtime` section records the same aggregate compact-strip counts without item names or image data.
13. Clear or block scanning and confirm an empty strip says `No scan yet` instead of `No hidden icons`.
14. Let the latest scan become stale and confirm available hidden icons remain visible.
15. Click an overflow `+N` control, when present, and confirm the full Second Bar management panel opens.

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
10. Open Settings -> Diagnostics and confirm `Last Activation Result`, `Last Activation Matrix`, `Last Activation Zone`, `Last Activation Visited`, and `Last Activation AX Error` match the attempted activation without showing the item name.
11. Export diagnostics as JSON or text and confirm `Second Bar Runtime` records the same last activation fields without item names or image data.
12. Export diagnostics as JSON and run `scripts/qa_second_bar_manual_gate_audit.sh --matrix-output docs/testing/pro-second-bar-direct-activation-matrix.generated.md path/to/diagnostics.json`. The audit requires `Last Icon Warm-up` to report at least one refreshed thumbnail by default; use `--min-warmed-icons N` only when the tested setup intentionally has a different minimum.
13. For notch-specific sign-off, rerun the audit with `--require-notch-avoidance`; for retry/failure sign-off, rerun it with `--require-failure-row`.
14. Review generated rows and copy accepted rows into `docs/testing/pro-second-bar-direct-activation-matrix.md`.
15. After all Gate C Second Bar rows are updated, run `scripts/qa_second_bar_signoff_audit.sh` and keep working until it passes.

## Regression Checks

1. Right-click the status item and confirm the status menu still opens.
2. Option-click the status item and confirm reveal-all behavior still works when enabled.
3. Confirm `Hide Second Bar` can close either the full panel or compact strip.
4. Confirm Basic Mode remains usable after revoking all Pro permissions.
5. Confirm no network access is required for compact strip behavior.
6. Disable Pro and confirm `Use menu bar icon for Second Bar` is cleared.
7. Launch in Safe Mode with `Use menu bar icon for Second Bar` previously enabled and confirm left-click falls back to Basic inline hide/show instead of opening compact strip.
