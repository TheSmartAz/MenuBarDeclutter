# Second Bar v0.1.3

Status: Preview, Pro Discovery gated. The newer Pro compact/status-menu entry point adds Accurate Icons and Screen Recording to the readiness gate.

Second Bar is a floating metadata/icon browser for hidden and always-hidden menu bar items. It uses Accessibility metadata and prefers Accurate Icons rendered thumbnails when that separate opt-in permission path is enabled; otherwise it falls back to bundle/app icons.

## v0.1.3 Focus

- Repositions when displays change, active Space changes, or screens wake.
- Recovers remembered positions that are no longer reachable.
- Keeps the panel within visible screen frames and models notch avoidance.
- Routes item actions through Command Center: reveal, highlight, show in Find Icon, open owning app, group actions, and Assisted Move gates.
- Shows Safe Mode, no-scan, and stale-scan explanations instead of failing silently.
- Keeps Basic Mode usable when Pro Discovery is unavailable.

## Gates

The v0.1.3 management panel requires:

- Pro Mode enabled.
- Accessibility Discovery enabled.
- macOS Accessibility permission granted.
- Safe Mode inactive.
- A usable scan or a clear stale/no-scan state.

The Pro compact strip and `Show Second Bar` command require the stricter current readiness gate:

- Pro Mode enabled.
- Accessibility Discovery enabled.
- macOS Accessibility permission granted.
- Accurate Icons enabled.
- Screen Recording permission granted.

## Boundaries

Second Bar does not request Screen Recording automatically, automate broad clicking, use private APIs, or use the network. Accurate Icons may provide local rendered thumbnails only when enabled from Privacy settings and after the explicit Screen Recording permission path succeeds.

It is not a live system menu bar clone. Some menu extras may not expose useful metadata, and uncapturable items fall back to their last rendered thumbnail or app icon.

## Verification

- `SecondBarPositioningServiceTests`
- `SecondBarViewModelTests`
- `MenuBarCommandRouterTests`
- `docs/testing/manual-qa.md`
