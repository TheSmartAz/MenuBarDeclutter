# Icon Moving Boundary

MenuBarDeclutter has three icon-placement layers. They are intentionally different.

## Intended Stable Pending Physical QA: Guided Manual Arrange

- User performs normal macOS Command-drag.
- No Pro Mode required.
- No Accessibility required.
- No automation.
- Recommended for everyday setup.
- Physical release completion still requires the manual Command-drag QA pass.

## Preview: Placement Planner

- Requires Pro Mode, Accessibility Discovery, and Accessibility permission.
- Reads local Accessibility metadata.
- Suggests manual instructions.
- Does not move anything.
- Fails closed when metadata is missing or stale.

## Experimental: Assisted Move

- Requires Pro gates plus Icon Moving enablement.
- Requires first-use and per-move confirmation.
- Tries one item at a time.
- May fail on system items or third-party apps.
- Must offer recovery if a move fails.

Assisted Move is not stable automated moving. It is not bulk movement. It does not use private menu bar APIs, Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, telemetry, or pixel capture.
