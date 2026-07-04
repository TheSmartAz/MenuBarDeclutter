# Known Risk Areas

These areas must be treated as Alpha RC risks until hands-on QA says otherwise.

## Manual Menu Bar Placement

- Real Command-drag separator placement depends on macOS menu bar behavior and user precision.
- Automated tests cannot validate the user's menu bar order.
- Risk: separator may be misplaced after display changes or if the user drags it to an unexpected slot.

## Icon Moving

- Experimental and disabled by default.
- Uses simulated Command-drag through public event APIs.
- May fail depending on macOS behavior, display layout, third-party menu bar apps, system items, timing, or Accessibility metadata.
- Must never run from launch, wake, profile apply, smart triggers, or URL automation.

## Accessibility Metadata

- AX item labels, frames, and ownership metadata can be incomplete, stale, or unavailable.
- Find Icon and Second Bar must degrade cleanly when scans fail or permission is revoked.

## Accurate Icons

- Rendered icon capture depends on Screen Recording permission, current display geometry, appearance, and whether the item is visibly rendered.
- Hidden items can be refreshed through the reveal sweep only for states MenuBarDeclutter can temporarily reveal with public APIs.
- Overflow, notch-hidden, or otherwise non-rendered items must fall back to the last rendered thumbnail or app icon.

## External Displays And Notches

- Display geometry, scaling, primary-display changes, and notch avoidance require real hardware QA.
- Disconnecting a display while collapsed is a high-priority recovery scenario.

## Launch At Login

- `SMAppService.mainApp` must be tested from an installed, signed app.
- Xcode-run behavior can differ from installed-app behavior.
- Stale Login Items entries may require removing entries in System Settings before retrying.

## Network Monitoring

- The app is intended to open no network connections through Phase 9.1.
- `scripts/qa_network_watch.sh` provides manual `lsof` / `nettop` commands; it does not enforce automatically.

## Deferred Features

- Private/offscreen menu bar item capture is intentionally not implemented.
- Focus and Wi-Fi trigger providers remain inactive until safe providers are added.
