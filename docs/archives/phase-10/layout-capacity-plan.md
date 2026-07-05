# Phase 10 Layout Capacity Plan

Date: 2026-06-29

## Goal

Phase 10 improves how MenuBarDeclutter helps users fit and reach menu bar
items without adding visual capture or sensitive permissions. The capacity
model is advisory: it estimates crowding, suggests safer workflows, and can
route difficult reveals to existing app-owned surfaces.

## Privacy Boundary

The plan deliberately excludes:

- ScreenCaptureKit and screen or pixel capture.
- Screen Recording permission.
- Apple Events and AppleScript automation.
- Input Monitoring.
- Network access, telemetry, or cloud sync.
- Private APIs or automatic third-party icon moves.

Basic Mode remains fully usable without Accessibility. Pro Mode can improve
estimates with existing Accessibility snapshots, but the layout features still
degrade to geometry-only estimates when Pro data is unavailable.

## Architecture

The Phase 10 entrypoint is `LayoutCoordinator`. It owns the layout services
and receives references to the existing app services instead of pushing layout
logic into `AppDelegate`.

Core services:

- `LayoutCapacityService`: produces Basic geometry estimates and Pro AX-backed
  estimates.
- `LayoutSuggestionService`: turns capacity and settings into non-invasive
  recommendations.
- `FullMenuBarModeService`: manages temporary reveal/configuration mode.
- `CrowdedRevealRescueService`: chooses Second Bar or Full Menu Bar Mode when
  inline reveal is likely to be unreachable.
- `SpacerItemStore`, `SpacerStatusItemController`, and
  `SpacerStatusItemFactory`: manage app-owned spacer/divider status items.
- `MenuBarSpacingService`: Labs-only spacing backup, dry-run/apply, restore,
  and reset flow.

Pure layout inputs are passed through `LayoutSettings` snapshots so lower-level
logic does not depend on `SettingsStore`.

## Capacity Model

Basic Mode uses only local screen geometry:

- screen frame and visible frame,
- estimated menu bar width,
- conservative average item width,
- current hiding visibility counts when known.

Pro Mode may add existing AX snapshots:

- known item count,
- visible/hidden/always-hidden counts,
- occupied width from AX frames where available,
- stale-snapshot warnings when data is old.

The estimator never attempts hardware model detection. It uses conservative
notch or constrained-center warnings from existing screen geometry and Second
Bar positioning assumptions.

## User-Facing Behavior

Capacity output is shown in Settings under Layout:

- estimated used capacity ratio,
- estimated slots and used slots,
- source: Basic estimate or Pro AX estimate,
- warnings and recommended next action.

Suggestions never silently enable Pro Mode, never apply spacing changes, and
never run icon moves. Experimental actions remain behind explicit Labs UI.

## Recovery And Safe Mode

Health and Safe Mode integration must keep layout features recoverable:

- exit Full Menu Bar Mode if it becomes stale,
- hide optional spacer items,
- reset app layout state without mutating global menu bar defaults,
- keep Settings and Diagnostics reachable.

Spacing Labs recovery can recommend Restore Previous, but health repair must
not silently change global macOS defaults.

## Validation

Phase 10 validation covers:

- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `scripts/verify_privacy_boundary.sh`
- `scripts/qa_preflight.sh`

Unit tests cover geometry-only capacity, Pro snapshot capacity, suggestions,
Full Menu Bar Mode, crowded rescue, spacer persistence, spacing backup/restore,
settings defaults, diagnostics export, and health recovery.
