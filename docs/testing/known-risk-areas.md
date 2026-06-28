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

- Phase 10 visual icon capture is intentionally not implemented.
- Second Bar uses app/bundle icons and AX metadata, not captured menu bar pixels.
- Focus and Wi-Fi trigger providers remain inactive until safe providers are added.
