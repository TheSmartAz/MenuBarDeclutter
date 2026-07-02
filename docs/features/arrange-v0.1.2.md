# Arrange v0.1.2

Status: Intended Stable for Guided Manual Arrange pending physical QA, Preview for Placement Planner, Experimental for Assisted Move.

Arrange is the normal icon-placement workflow in `v0.1.2`. It explains the MenuBarDeclutter control item, separator, hidden area, optional always-hidden area, collapse/reveal tests, reset layout, and Recovery.

## Required Flow

The Arrange page presents these user-facing cards:

- How menu bar hiding works
- Step 1: place the control item
- Step 2: place the separator
- Step 3: move clutter into the hidden area
- Step 4: test collapse
- Step 5: test reveal
- Optional: always-hidden area
- Need help? Reset layout or open Recovery

## Intended Stable Actions Pending Physical QA

- Expand
- Collapse
- Reveal All
- Reset Layout
- Show Drag Hint

These actions are Basic Mode friendly and do not require Pro Mode or Accessibility. Final release completion still depends on the physical Command-drag and live menu bar checks tracked in `docs/testing/manual-v0.1.2-results.md`.

## Boundaries

Arrange must not request Accessibility during the intended stable manual flow, use Screen Recording, use ScreenCaptureKit, capture screenshots/pixels, control third-party menu extras through private APIs, make bulk icon movement stable, or hide recovery behind Advanced.

Placement Planner remains Preview and advisory. Assisted Move remains Experimental and explicitly gated.
