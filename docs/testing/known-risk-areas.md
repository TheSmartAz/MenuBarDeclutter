# Known Risk Areas

Last reviewed: 2026-07-05

These areas need explicit QA evidence before making stronger release claims.

## Manual Menu Bar Placement

- Real Command-drag separator placement depends on macOS menu bar behavior and user precision.
- Automated tests cannot validate the user's real menu bar order.
- Display changes can make a previously useful separator position less useful.

## Accessibility Metadata

- AX item labels, frames, and ownership metadata can be incomplete, stale, unavailable, or inconsistent across third-party menu bar apps.
- Find Icon, Second Bar, groups, placement helpers, and workspace assignment must degrade cleanly when scans fail or permission is revoked.

## Accurate Icons

- Rendered icon capture depends on Screen Recording permission, current display geometry, appearance, and whether the item is visibly rendered.
- Hidden, overflow, notch-hidden, offscreen, or non-rendered items must fall back to stale thumbnails or app icons.
- Basic Mode must never depend on Screen Recording or ScreenCaptureKit.

## Icon Moving

- Experimental and disabled by default.
- Uses simulated Command-drag through public event APIs after explicit user action.
- May fail depending on macOS behavior, display layout, third-party menu bar apps, system items, timing, and Accessibility metadata.
- Must never run from launch, wake, profile apply, smart triggers, URL automation, or App Intents.

## External Displays And Notches

- Display geometry, scaling, primary-display changes, notch avoidance, and panel placement require real hardware QA.
- Disconnecting a display while collapsed is a high-priority recovery scenario.

## Launch At Login

- `SMAppService.mainApp` must be tested from an installed app.
- Xcode-run behavior can differ from `/Applications` behavior.
- Stale Login Items entries may require user cleanup in System Settings before retrying.

## Installed-App And Gatekeeper Behavior

- The current project stance does not require Developer ID signing, notarization, or stapling.
- Non-notarized dry-run artifacts can hit local `spctl` or system-policy instability; record exact output and distinguish it from app runtime launch failures.

## Network Monitoring

- The app is intended to open no network connections for Basic Mode or current Preview/Labs/Experimental surfaces.
- Use `scripts/qa_network_watch.sh` or the installed-app smoke probe when making runtime no-network claims.

## Deferred Features

- Private/offscreen menu bar item capture is intentionally not implemented.
- Apple Events control, Input Monitoring, network/cloud sync, telemetry, analytics, crash upload, remote config, and stable automated physical icon moving remain out of scope.
