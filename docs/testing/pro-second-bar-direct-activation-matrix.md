# Pro Second Bar Direct Activation Matrix

Last updated: 2026-07-06

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

- `PASS`: Clicking the compact strip icon opens or performs the same action as the real menu bar item.
- `FAIL_TARGET_NOT_FOUND`: The AX element was not found.
- `FAIL_AX_PRESS`: The element was found but rejected `AXPress`.
- `FAIL_MISSING_METADATA`: The saved target lacks enough owner metadata to attempt direct activation.
- `FAIL_STALE_METADATA`: The owner app quit, relaunched, or moved its item after the scan.
- `PARTIAL`: The app opens, but behavior differs from the real menu bar item.
- `BLOCKED`: Permission, hardware, or setup state prevented the test.

## Matrix

| Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| YYYY-MM-DD | 26.x | local/dev | chat/cloud/vpn/calendar/utility | hidden | yes/no | PASS | not-needed/retried-pass/retried-fail | item-id | hidden | 0 | none |  |

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
