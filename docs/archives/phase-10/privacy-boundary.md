# Phase 10 Privacy Boundary

## No New Permissions Required

Phase 10 does not request:
- Screen Recording
- ScreenCaptureKit
- Apple Events
- Input Monitoring
- Network access
- Telemetry
- Cloud sync

## Basic Mode (permission-free)
- Capacity estimation uses screen geometry only.
- Full Menu Bar Mode uses existing separator-based reveal.
- Crowded Reveal Rescue uses existing Second Bar / Full Menu Bar Mode.
- Spacer/Divider items are app-owned NSStatusItem instances.
- Layout suggestions are computed locally.

## Pro Mode (opt-in, Accessibility only)
- Capacity estimation improves with AX snapshots.
- No new permissions beyond existing Accessibility.

## Menu Bar Spacing Labs
- Uses UserDefaults only (no private APIs).
- Experimental, off by default.
- Explicit, reversible, backed up.
- Never restarts system processes automatically.
- Dry-run mode when `enableUndocumentedSpacingDefaults` is false.

## Diagnostics
- Layout diagnostics log only privacy-safe metadata (ratios, counts, statuses).
- No item names, no screen contents, no personal data.
