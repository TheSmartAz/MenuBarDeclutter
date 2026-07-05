# Privacy QA

Use this checklist for current release validation and privacy-sensitive changes.
For routine patch scope, first choose the appropriate lane in
`docs/testing/qa-process.md`.

`scripts/verify_privacy_boundary.sh` is the source of truth for
static/source/bundle privacy checks. Manual privacy QA should focus on runtime
prompts, explicit opt-in, permission revocation, degraded states, diagnostics
export review, and network observation.

Mark each item `PASS`, `FAIL`, `BLOCKED`, `PARTIAL`, or `NOT TESTED`.

## Static Verification

| Check | Result | Notes |
| --- | --- | --- |
| `scripts/verify_privacy_boundary.sh` passes | NOT TESTED | |
| No network entitlements are present | NOT TESTED | |
| ScreenCaptureKit imports are scoped to `MenuBarIconCapture` | NOT TESTED | |
| Screen Recording usage string is scoped to Accurate Icons | NOT TESTED | |
| No Apple Events usage string is present | NOT TESTED | |
| No Input Monitoring usage string is present | NOT TESTED | |
| `menubardeclutter://` URL scheme is local and registered | NOT TESTED | |

## Basic Mode Runtime

| Scenario | Expected Result | Result | Notes |
| --- | --- | --- | --- |
| First launch with default settings | No permission prompt appears | NOT TESTED | |
| Collapse/expand/reveal all | No sensitive permission prompt appears | NOT TESTED | |
| Auto-rehide and hover reveal | No Input Monitoring prompt appears | NOT TESTED | |
| Global hotkey | Works without Input Monitoring prompt | NOT TESTED | |
| Diagnostics export | Excludes screenshots, screen contents, live query text, selected item identity, and network data | NOT TESTED | |

## Pro Mode Runtime

| Scenario | Expected Result | Result | Notes |
| --- | --- | --- | --- |
| Pro Mode disabled | Find Icon and Second Bar show unavailable states; Basic Mode works | NOT TESTED | |
| Enable Pro Mode without requesting Accessibility | No prompt appears until explicit request | NOT TESTED | |
| Request Accessibility permission | System Accessibility prompt appears | NOT TESTED | |
| Revoke Accessibility | Pro surfaces degrade; Basic Mode still works | NOT TESTED | |
| Icon moving disabled by default | No move is available until explicitly enabled | NOT TESTED | |
| Enable icon moving | Experimental warning appears before enablement | NOT TESTED | |

## Accurate Icons Runtime

| Scenario | Expected Result | Result | Notes |
| --- | --- | --- | --- |
| Accurate Icons disabled | No Screen Recording prompt appears | NOT TESTED | |
| Enable Accurate Icons without requesting permission | UI shows missing permission without prompting automatically | NOT TESTED | |
| Request Screen Recording from Accurate Icons | System Screen Recording flow appears from explicit action | NOT TESTED | |
| Revoke Screen Recording | Surfaces degrade to stale thumbnails or app icons; Basic Mode still works | NOT TESTED | |
| Diagnostics export after capture | Export excludes rendered thumbnails and screen contents | NOT TESTED | |

## Network Watch

Run:

```sh
scripts/qa_network_watch.sh MenuBarDeclutter
```

Expected: no network connections in Basic Mode, Optional Pro Discovery, Accurate Icons, or current Preview/Labs/Experimental surfaces.
