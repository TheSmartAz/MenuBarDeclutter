# Pro Second Bar Direct Activation Matrix

Last updated: 2026-07-07

Use this matrix to collect third-party compact strip activation behavior. Record stable diagnostic IDs from logs, not private readable item names, unless the tester intentionally adds a public app label for local debugging.

## Helper Script

After exporting diagnostics as JSON, run the manual gate audit first. It checks
the readiness/runtime evidence and can generate draft matrix rows in one pass:

```sh
scripts/qa_second_bar_manual_gate_audit.sh \
  --matrix-output docs/testing/pro-second-bar-direct-activation-matrix.generated.md \
  --app-category utility \
  --dynamic-icon no \
  path/to/diagnostics.json
```

Use `--retry-result retried-pass` or `--retry-result retried-fail` after testing the retry control. For stricter sign-off runs, add `--require-notch-avoidance` after testing notch fallback placement, and `--require-failure-row` after testing stale or failed activation retry. The audit reads only sanitized diagnostics metadata and writes markdown rows that can be reviewed before being added to this file.

The audit also checks the last Accurate Icons warm-up result and requires at
least one refreshed thumbnail by default. Use `--min-warmed-icons N` only when
the tested setup intentionally needs a different threshold.

After adding reviewed rows to this file, check the required matrix breadth:

```sh
scripts/qa_second_bar_matrix_coverage.sh docs/testing/pro-second-bar-direct-activation-matrix.md
```

The lower-level row generator remains available when only matrix rows are needed:

```sh
scripts/qa_second_bar_activation_matrix.sh --app-category utility --dynamic-icon no path/to/diagnostics.json
```

## Result Values

- `PASS`: Clicking the compact strip icon opens or performs the same action as the real menu bar item. Direct activation may use public `AXPress`, public `AXShowMenu`, or the guarded CGEvent click fallback when AX actions are unavailable.
- `FAIL_TARGET_NOT_FOUND`: The AX element was not found.
- `FAIL_AX_PRESS`: The element was found, but `AXPress`, `AXShowMenu`, and the guarded click fallback were unavailable or rejected.
- `FAIL_MISSING_METADATA`: The saved target lacks enough owner metadata to attempt direct activation.
- `FAIL_STALE_METADATA`: The owner app quit, relaunched, or moved its item after the scan.
- `PARTIAL`: The app opens, but behavior differs from the real menu bar item.
- `BLOCKED`: Permission, hardware, or setup state prevented the test.

## Matrix

| Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | unknown | hidden | unknown | FAIL_AX_PRESS | not-recorded | mbd-70f505a0d2e8aaec | hidden | 1 | AXError(rawValue: -25206) | Menu bar item did not accept AXPress. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | unknown | hidden | unknown | PASS | not-recorded | mbd-3e2d7db7ddc62aa8 | hidden | 5 | none | Menu bar item activated. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | chat/stateful | hidden | yes | PASS | not-needed | mbd-a0e3c9a46b26610b | hidden | 2 | none | Third-party chat/status item activated from compact strip; target window became visible, matching the observed menu bar item behavior. Evidence: `build/qa-artifacts/second-bar-live/real-third-party/wechat-observed-final.json` and `build/qa-artifacts/second-bar-live/real-third-party/observed-third-party-activation-evidence.txt`. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | utility/menu | hidden | no | PASS | not-needed | mbd-6834efd6eb919c9a | hidden | 2 | none | Third-party utility/template menu-style item; guarded CGEvent fallback opened a real AX menu with 45 visible menu-ish elements and a target-owned menu CGWindow. Evidence: `build/qa-artifacts/second-bar-live/real-third-party/magnet-observed-final.json` and `build/qa-artifacts/second-bar-live/real-third-party/observed-third-party-activation-evidence.txt`. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | utility/vpn/menu/stateful | hidden | yes | PASS | not-needed | mbd-96a9d4f9657a98a7 | hidden | 2 | none | Third-party stateful network utility menu-style item; compact-strip activation opened a real AX menu and target-owned menu CGWindow. Evidence: `build/qa-artifacts/second-bar-live/real-third-party/surge-observed-final.json` and `build/qa-artifacts/second-bar-live/real-third-party/observed-third-party-activation-evidence.txt`. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | utility/menu | hidden | no | FAIL_TARGET_NOT_FOUND | not-recorded | mbd-6834efd6eb919c9a | hidden | 0 | none | Stale/relaunch coverage: Magnet was present in the compact strip, its owner app was told to terminate before clicking the retained compact-strip button, the target menu bar item disappeared from the matchable AX tree, activation failed in-strip with Retry available, and Magnet was relaunched afterward. Evidence: `build/qa-artifacts/second-bar-live/stale-relaunch/magnet-owner-quit-stale.json` and `build/qa-artifacts/second-bar-live/stale-relaunch/magnet-owner-quit-stale-evidence.txt`. |
| 2026-07-07 | Version 26.1 (Build 25B78) | 0.1.10 build 11 | permission-gate | hidden | no | BLOCKED | not-needed | ui-testing-accessibility-revoked | hidden | 0 | none | Controlled permission revoked coverage: screenshot QA launches with `--ui-testing-accessibility-revoked-after-launch` after setup-ready flags, then captures the compact requirements strip instead of allowing activation. Actual local macOS TCC permissions remain granted. Evidence: `docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2/manifest.tsv` row `34-compact-second-bar-accessibility-required` and `screenshots/34-compact-second-bar-accessibility-required.png`. |
| YYYY-MM-DD | 26.x | local/dev | chat/cloud/vpn/calendar/utility | hidden | yes/no | PASS | not-needed/retried-pass/retried-fail | item-id | hidden | 0 | none |  |

## Local Fixture Evidence

Local fixture rows are implementation evidence only and do not count toward the
third-party breadth requirements below.

- 2026-07-07: `build/qa-artifacts/second-bar-live/after-cgevent-top-origin-batch.json` recorded 8 compact-strip activation rows, all `PASS`; 6 rows used `Menu bar item activation click fallback dispatched.` after the item rejected AX actions. `scripts/qa_second_bar_manual_gate_audit.sh --matrix-output docs/testing/pro-second-bar-direct-activation-matrix.generated.md build/qa-artifacts/second-bar-live/after-cgevent-top-origin-batch.json` passed with one warning because this all-PASS export has no failure row.
- 2026-07-07: `MBD_LIVE_FIXTURE_TEST=1 xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AXMenuBarScannerLiveFixtureTests` passed after the fallback update, covering fixture scanning and menu-style `AXShowMenu` activation.

## Real Third-Party Evidence

- 2026-07-07: With the MenuBarDeclutter separator temporarily moved right so real third-party items entered the hidden zone, compact-strip clicks were exercised for WeChat, Magnet, and Surge. `build/qa-artifacts/second-bar-live/real-third-party/observed-third-party-activation-evidence.txt` records public AX/CGWindow evidence after each click: WeChat made its target window visible, Magnet opened a standard AX menu via the guarded click fallback, and Surge opened a standard AX menu. Matching diagnostics exports are `wechat-observed-final.json`, `magnet-observed-final.json`, and `surge-observed-final.json`.
- 2026-07-07: `build/qa-artifacts/second-bar-live/stale-relaunch/magnet-owner-quit-stale-evidence.txt` records a real stale/relaunch failure path. Magnet was present in the compact strip, its owner app was told to terminate before the retained compact-strip button was clicked, the stale target returned `FAIL_TARGET_NOT_FOUND`, and the strip stayed visible with Retry available. Magnet was relaunched after evidence capture.
- 2026-07-07: `docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2/manifest.tsv` row `34-compact-second-bar-accessibility-required` records controlled permission-revoked coverage using `--ui-testing-accessibility-revoked-after-launch`. This verifies the readiness gate blocks compact activation and shows the requirements strip without disturbing the developer machine's actual granted TCC permissions.
- 2026-07-07: System popover candidate attempts are preserved but not counted. `build/qa-artifacts/second-bar-live/popover/control-center-popover-evidence.txt` recorded compact-strip `PASS` rows for Control Center candidates, but public AX/CGWindow evidence and screenshot `build/qa-artifacts/second-bar-live/popover/screenshots/control-center-after-compact-click.png` did not show a real popover. `build/qa-artifacts/second-bar-live/popover/system-popover-evidence.txt` did not produce stable Spotlight/SystemUIServer compact-strip activations. Keep popover-style coverage open until two targets produce visible popover evidence.

## Required Coverage

| Category | Minimum Cases | Notes |
| --- | ---: | --- |
| Utility/template icon | 2 | Common monochrome status items. |
| Colored/dynamic icon | 2 | Calendar, sync, recording, or stateful apps. |
| Popover-style item | 2 | Items that open a custom popover. |
| Menu-style item | 2 | Items that open a standard menu. |
| Relaunch/stale item | 1 | Relaunch owner app after scan, then activate from compact strip. |
| Permission revoked | 1 | Revoke Accessibility after setup and verify the readiness gate blocks activation. |

## Diagnostics To Capture

1. Export diagnostics after each failure.
2. Run `scripts/qa_second_bar_manual_gate_audit.sh` against the JSON export, then review the generated row for `targetID`, `targetZone`, `matrixResult`, `visitedElementCount`, `axError`, and `message`.
3. When a compact-strip activation fails, confirm the strip remains open, click `Retry`, and record the retry result.
4. Do not attach screenshots, raw screen captures, or rendered icon thumbnail files.
5. If a failure is reproducible with a public app, add the app category and behavior notes; otherwise keep the entry generic.
6. Run `scripts/qa_second_bar_matrix_coverage.sh` before marking the direct activation matrix complete.
