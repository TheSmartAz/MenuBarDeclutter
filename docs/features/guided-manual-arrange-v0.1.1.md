# Guided Manual Arrange v0.1.1

Status: Stable.

Guided Manual Arrange is the stable `v0.1.1` icon placement workflow. It teaches the user to place MenuBarDeclutter's control item, separator, hidden items, and optional always-hidden area with normal macOS Command-drag.

This feature is part of Basic Mode. It does not require Pro Mode, Accessibility, metadata discovery, automation, or simulated dragging.

## User Goal

A user should be able to open Arrange and understand:

- where the MenuBarDeclutter control item should live
- what the primary separator does
- which side of the separator hides items
- how to place always-hidden items when enabled
- how to test collapse, reveal, and reset
- how to recover if the layout looks wrong

## Recommended Arrange Steps

1. Show MenuBarDeclutter controls.
2. Hold Command and drag the MenuBarDeclutter control item to the desired visible position.
3. Hold Command and drag the primary separator to mark the hidden boundary.
4. Put items to hide on the hidden side of the separator.
5. Collapse and confirm the hidden area disappears.
6. Reveal all and confirm hidden items are reachable.
7. Enable and place the always-hidden area only if the user wants a stricter zone.
8. Use reset layout or Safe Mode instructions if anything becomes confusing.

## Arrange Page Requirements

The Arrange page should provide:

- a short Command-drag guide
- app-owned diagrams instead of screenshots
- clear labels for visible, hidden, and always-hidden zones
- buttons for expand, collapse, reveal all, and reset layout
- a link for "I can't find the control item"
- a recovery path to Safe Mode, reset layout, and diagnostics export
- a Preview Placement Planner entry point when Pro gates are satisfied
- an Experimental Assisted Move entry point only after explicit opt-in

## Boundaries

Guided Manual Arrange must not:

- request Pro Mode
- request Accessibility
- try to control third-party menu extras
- simulate dragging
- make Assisted Move look stable
- hide recovery behind Advanced

## Relationship To Other Placement Tools

| Tool | Status | Role |
| --- | --- | --- |
| Guided Manual Arrange | Stable | Recommended path for placing icons safely. |
| Placement Planner | Preview | Suggests manual placement from discovered metadata when Pro gates are satisfied. |
| Assisted Move | Experimental | Attempts one confirmed move and must provide dry-run, verification, and recovery. |

## Manual QA

Use this checklist when the Arrange page or onboarding step changes:

- Open Arrange from Settings.
- Open Arrange from the status menu if that route exists.
- Follow the Command-drag guide for the control item.
- Follow the Command-drag guide for the primary separator.
- Move one normal item to the hidden side manually.
- Collapse and confirm the item is hidden.
- Reveal all and confirm the item is reachable.
- Use reset layout and confirm the app returns to a usable expanded state.
- Confirm no Pro or Accessibility prompt appears during the stable manual flow.
