# Phase 10 Known Limitations

- Capacity estimates without Pro Mode are approximate, using a conservative
  average item width of ~30pt.
- Full Menu Bar Mode does not move icons; it only reveals all sections.
- Crowded Reveal Rescue is conservative and can be overridden by the user.
- Spacer items are app-owned and do not hide third-party icons.
- Menu Bar Spacing Labs is experimental. It may not work in all sandbox
  configurations. It operates in dry-run mode by default.
- Spacing Labs never automatically restarts SystemUIServer or ControlCenter.
- No ScreenCaptureKit visual icon capture (intentionally deferred).
