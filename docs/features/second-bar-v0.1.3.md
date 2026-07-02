# Second Bar v0.1.3

Status: Preview, Pro Discovery gated.

Second Bar is a floating metadata/icon browser for hidden and always-hidden menu bar items. It uses Accessibility metadata and bundle/app icons, not captured menu bar pixels.

## v0.1.3 Focus

- Repositions when displays change, active Space changes, or screens wake.
- Recovers remembered positions that are no longer reachable.
- Keeps the panel within visible screen frames and models notch avoidance.
- Routes item actions through Command Center: reveal, highlight, show in Find Icon, open owning app, group actions, and Assisted Move gates.
- Shows Safe Mode, no-scan, and stale-scan explanations instead of failing silently.
- Keeps Basic Mode usable when Pro Discovery is unavailable.

## Gates

Second Bar requires:

- Pro Mode enabled.
- Accessibility Discovery enabled.
- macOS Accessibility permission granted.
- Safe Mode inactive.
- A usable scan or a clear stale/no-scan state.

## Boundaries

Second Bar does not request Screen Recording, use ScreenCaptureKit, sample pixels, automate broad clicking, use private APIs, or use the network.

It is not a pixel-perfect duplicate of the real menu bar. Some menu extras may not expose useful metadata.

## Verification

- `SecondBarPositioningServiceTests`
- `SecondBarViewModelTests`
- `MenuBarCommandRouterTests`
- `docs/testing/manual-v0.1.3-system-qa.md`
