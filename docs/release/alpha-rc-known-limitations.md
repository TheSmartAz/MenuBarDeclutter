# Alpha RC Known Limitations

- Phase 10 visual icon capture is intentionally not implemented.
- Second Bar uses app/bundle icons and Accessibility metadata, not captured menu bar pixels.
- Icon moving is experimental, disabled by default, and may fail depending on macOS, display layout, and third-party menu bar apps.
- Some system menu bar items may not be movable or discoverable.
- Accessibility metadata can be incomplete, stale, or unavailable.
- Profiles do not silently run mass icon moves; Pro moves are report-only during normal profile apply.
- Smart triggers are local and conservative; Focus and Wi-Fi providers remain inactive until safe providers are added.
- Launch at Login must be validated from an installed signed app, not only from Xcode.
- External display, notch, and sleep/wake behavior require hands-on hardware QA.
- No ScreenCaptureKit, Screen Recording permission, Apple Events, Input Monitoring, network access, telemetry, or cloud sync is included.
