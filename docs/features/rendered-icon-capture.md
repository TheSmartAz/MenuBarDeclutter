# Accurate Icons Rendered Capture

Status: Opt-in, public API only.

Accurate Icons treats a discovered menu bar item as rendered pixels plus metadata, not as an app bundle icon. When enabled, MenuBarDeclutter captures small menu bar item thumbnails locally and uses them in Second Bar, Find Icon, item settings, and group picker surfaces before falling back to app icons. Pro Second Bar compact strip readiness requires Accurate Icons plus Screen Recording so the strip can show prepared rendered icons.

## Permission Boundary

- Basic Mode does not request Screen Recording.
- Accurate Icons is off by default.
- The Screen Recording prompt is shown only from the explicit Privacy settings button.
- Captured thumbnails are stored locally and excluded from diagnostics exports.
- The cache can be cleared from Privacy settings.

## Capture Order

1. Fresh rendered thumbnail from visible menu bar item frame.
2. Rendered thumbnail after an opt-in reveal sweep for items hidden by MenuBarDeclutter.
3. Last rendered thumbnail for the same item identity.
4. Bundle/app icon fallback.
5. Generic app placeholder.

## Constraints

This implementation uses public ScreenCaptureKit visible-region capture only. It does not use private CGS APIs, reverse-engineered menu bar window enumeration, or offscreen menu bar item capture. Items that macOS does not visibly render may not have fresh thumbnails.
