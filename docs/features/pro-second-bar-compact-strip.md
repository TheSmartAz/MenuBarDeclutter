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
- Safe Mode: left click falls back to Basic inline hide/show; it does not open Second Bar or the compact strip.
- Status menu and automation `Show Second Bar`: open Second Bar only when the same readiness gate passes; otherwise show or report the missing requirement.
- Right-click status menu keeps inline Expand, Collapse, Reveal All, and Reset actions as secondary recovery tools.

## Compact Strip

The compact strip is a one-line, menu-bar-like app-owned floating surface.

- It shows Hidden zone items only.
- It excludes Always Hidden by default.
- It only admits Hidden-zone items from the right-side menu bar status area: on notched displays, items must be to the right of the modeled notch; on non-notched displays, items must be in the right half of the active menu bar band.
- It excludes likely system items and MenuBarDeclutter's own status items.
- It admits Hidden-zone items even when a specific rendered thumbnail is not ready; Accurate Icons is the setup gate, while individual items can fall back to app or placeholder icons.
- It is icon-only by default; names are available through tooltips and accessibility labels.
- Its order follows the real Hidden zone x-position until Set support exists.
- Its item buttons use the original menu bar item frame size when available, with a small fallback slot only when AX frame data is missing or invalid.
- Overflow remains one line and appears as `+N`, which opens the Manage Panel. `+N` counts items that do not fit, not items whose rendered thumbnail is still missing.
- If no Accessibility scan is available, it shows `No scan yet` instead of claiming there are no hidden icons.
- If the latest Accessibility scan is stale, it keeps any ready icons visible and marks the strip as `Scan stale`.
- The strip does not repeat MenuBarDeclutter's own status item.
- Diagnostics live status and diagnostics export record aggregate counts for the last compact strip: visible items, overflow items, fallback-icon items, and scan state. They do not record item names or image data.

The strip should feel related to the macOS menu bar without pretending to be the system menu bar. It uses system bar material/vibrancy, compact menu-bar-like height, and only a slight boundary.

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

Opening the strip must not wait for a scan or screen capture. It immediately reads the latest Accessibility snapshot and rendered-icon cache, then refreshes scans and Accurate Icons in the background while the strip is already visible.

## Manage Panel

The existing large Second Bar panel remains the management surface.

- Search Hidden and Always Hidden.
- Show needs-icon, fallback-icon, and activation-health states.
- Refresh Accurate Icons explicitly.
- Carry future Set management.
- Keep favorites and recents out of compact strip ordering until Set support exists.

## HIG Boundary

The status item remains a shortcut into a temporary app-owned surface. The compact strip is transient, keyboard accessible, dismissible, and visually separate from the real system menu bar.

References:

- [Apple Human Interface Guidelines: The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Apple Human Interface Guidelines: Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers)
- [Apple Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
