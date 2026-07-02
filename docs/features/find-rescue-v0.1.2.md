# Find & Rescue v0.1.2

Status: Preview for Pro metadata surfaces, Stable for recovery handoff and Basic-mode availability.

Find & Rescue consolidates item-location workflows that answer:

> Where did my icon go, and how do I get it back?

## Included Workflows

- Find hidden icons
- Second Bar
- New Items
- Crowded menu rescue
- Collections
- Item actions
- Arrange and Recovery handoff

## Gates

Find & Rescue metadata depends on:

- Pro Mode
- Accessibility Discovery
- macOS Accessibility permission
- feature-specific toggles
- Safe Mode inactive

The page must clearly show missing gates and must not automatically prompt for Accessibility.

## Crowded Menu Rescue

v0.1.2 keeps rescue choices simple:

- try inline first
- open Second Bar when crowded
- ask before switching
- use Full Menu Bar Mode when appropriate

Advanced capacity details belong under Advanced, not the normal Find & Rescue path.

## Privacy

Find & Rescue does not use screenshots, Screen Recording, ScreenCaptureKit, Apple Events permission, Apple Events scripting/control of other apps, Input Monitoring, network access, telemetry, or private menu bar APIs. Second Bar uses app icons and metadata, not menu bar pixels.
