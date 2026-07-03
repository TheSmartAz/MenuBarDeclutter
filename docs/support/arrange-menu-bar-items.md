# Arrange Menu Bar Items

Use Arrange when the MenuBarDeclutter control, separator, or hidden items are not where you expect.

## Intended Stable Manual Flow Pending Physical QA

1. Open Settings -> Arrange or choose Arrange Items from the status menu.
2. Use Expand to show MenuBarDeclutter's app-owned controls.
3. Hold Command and drag the MenuBarDeclutter control item to a reachable visible spot.
4. Hold Command and drag the primary separator to mark the hidden boundary.
5. Put items you want hidden on the hidden side of the separator.
6. Use Collapse to test hiding.
7. Use Reveal All to confirm hidden items are still reachable.
8. Use Reset Layout if the control or separator placement becomes confusing.

This flow uses normal macOS menu bar behavior. It does not require Pro Mode, Accessibility, Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, or network access.

## Placement Planner

Placement Planner is Preview. It can suggest manual placement when Pro Discovery is available, but it does not move icons.

## Assisted Move

Assisted Move is Experimental. It can try one confirmed move only after Pro, Accessibility, Icon Moving, and confirmation gates pass. Manual Command-drag remains the recommended path.

## If You Cannot Find The Control Item

1. Open MenuBarDeclutter again from Applications.
2. Open the status menu if visible and choose Arrange Items or Recovery.
3. Use Reveal All and Reset Layout.
4. Request Safe Mode next launch from Recovery if the layout still seems broken. Option-launch Safe Mode remains a hands-on fallback path.
5. Export diagnostics from Recovery if you need to report a problem.
