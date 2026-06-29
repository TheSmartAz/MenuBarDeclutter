# Phase 11 Known Limitations

- Private Access gates UI actions; it is not encryption.
- Touch ID availability depends on device/system configuration.
- Protected groups can still be visible in the real macOS menu bar if the
  original third-party item is visible outside the app's UI.
- App Intents cannot bypass protected actions.
- Some shortcuts may require the app to be running.
- Group matching depends on bundle IDs/AX metadata and may be stale.
- No competitor config auto-import.
- No ScreenCaptureKit visual icon capture.
- App Intents return generic success without detailed dialog due to
  IntentDialog type limitations with dynamic strings.
