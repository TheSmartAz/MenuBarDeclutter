# Pro Second Bar Compact Strip

Status: implemented first Pro Second Bar slice; hardware permission QA remains manual.

## Product Model

MenuBarDeclutter keeps two user paths.

- Basic users keep the existing permission-free separator workflow. The primary status item click continues to hide or show the inline hidden area.
- Pro users can enable Second Bar. The status menu and automation `Show Second Bar` command use the Pro Second Bar readiness gate.
- Primary status item click opens the compact strip only after the user explicitly enables `Use menu bar icon for Second Bar`; readiness alone never silently changes the primary click.

Second Bar is a Pro feature. It is not enabled silently, and Basic Mode remains fully usable without Accessibility, Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, or network access.

## Ready Gate

The Pro Second Bar compact strip is ready only when all of these are satisfied:

- Pro entitlement is active, either trial or licensed.
- Accessibility Discovery is enabled.
- Accessibility permission is granted.
- Accurate Icons is enabled.
- Screen Recording permission is granted.

Warm-up capture improves icon quality but is not a permanent gate. A failed or partial warm-up puts items into a retry or needs-icon state instead of blocking Pro forever.

## Primary Click Routing

- Basic Mode: left click toggles inline hide/show.
- Pro entitlement active, primary-click opt-in off: left click still toggles inline hide/show, even when Second Bar is ready.
- Pro entitlement active, primary-click opt-in on, and Second Bar ready: left click toggles the compact strip.
- Pro entitlement active, primary-click opt-in on, but Second Bar not ready: left click opens a lightweight requirements strip.
- Status menu and automation `Show Second Bar`: open Second Bar only when the same readiness gate passes; otherwise show or report the missing requirement.
- Right-click status menu keeps inline Expand, Collapse, Reveal All, and Reset actions as secondary recovery tools.

## Compact Strip

The compact strip is a one-line, menu-bar-like app-owned floating surface.

- It shows Hidden zone items only.
- It excludes Always Hidden by default.
- It admits items with Accurate Icons ready.
- It is icon-only by default; names are available through tooltips and accessibility labels.
- Its order follows the real Hidden zone order until Set support exists.
- Overflow remains one line and appears as `+N`, which opens the Manage Panel.
- Search/Manage and Settings are fixed compact controls on the right.
- The strip does not repeat MenuBarDeclutter's own status item.

The strip should feel related to the macOS menu bar without pretending to be the system menu bar. It uses system material/vibrancy, a small height, and a slight floating boundary.

## Placement

The compact strip follows the clicked menu bar/status item screen.

- If the MenuBarDeclutter status item to right-edge region can fit the strip, use that region.
- Otherwise, use the notch-left-edge to right-edge region when a notch is modeled.
- Without a notch, clamp a right-aligned strip inside the visible screen frame.
- Display, Space, and wake changes should reposition or close the strip.

## Activation

Compact strip clicks are optimistic one-click activation.

1. Prefer direct Accessibility press on the original menu bar item.
2. Keep reveal plus simulated click plus restore as a Pro/Labs fallback until dogfood proves it stable.
3. If activation fails, keep the item visible in the strip and show a lightweight retry state.

Opening the strip must not trigger a scan or screen capture. It reads the latest Accessibility snapshot and rendered-icon cache. Accurate Icons refreshes happen during onboarding warm-up, visible-item refreshes, or explicit user refresh actions.

## Manage Panel

The existing large Second Bar panel remains the management surface.

- Search Hidden and Always Hidden.
- Show needs-icon and activation-health states.
- Refresh Accurate Icons explicitly.
- Carry future Set management.
- Keep favorites and recents out of compact strip ordering until Set support exists.

## HIG Boundary

The status item remains a shortcut into a temporary app-owned surface. The compact strip is transient, keyboard accessible, dismissible, and visually separate from the real system menu bar.

References:

- [Apple Human Interface Guidelines: The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Apple Human Interface Guidelines: Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers)
- [Apple Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
