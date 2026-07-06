# Pro Second Bar Direct Activation Matrix

Last updated: 2026-07-05

Use this matrix to collect third-party compact strip activation behavior. Record stable diagnostic IDs from logs, not private readable item names, unless the tester intentionally adds a public app label for local debugging.

## Result Values

- `PASS`: Clicking the compact strip icon opens or performs the same action as the real menu bar item.
- `FAIL_TARGET_NOT_FOUND`: The AX element was not found.
- `FAIL_AX_PRESS`: The element was found but rejected `AXPress`.
- `FAIL_MISSING_METADATA`: The saved target lacks enough owner metadata to attempt direct activation.
- `FAIL_STALE_METADATA`: The owner app quit, relaunched, or moved its item after the scan.
- `PARTIAL`: The app opens, but behavior differs from the real menu bar item.
- `BLOCKED`: Permission, hardware, or setup state prevented the test.

## Matrix

| Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | targetID | targetZone | visitedElementCount | axError | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| YYYY-MM-DD | 26.x | local/dev | chat/cloud/vpn/calendar/utility | hidden | yes/no | PASS | item-id | hidden | 0 | none |  |

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
2. Copy the `Second Bar activation result` log metadata fields: `targetID`, `targetZone`, `matrixResult`, `visitedElementCount`, `axError`, and `message`.
3. Do not attach screenshots, raw screen captures, or rendered icon thumbnail files.
4. If a failure is reproducible with a public app, add the app category and behavior notes; otherwise keep the entry generic.
