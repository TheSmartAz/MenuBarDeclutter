# Icon Moving v0.1.1

Status: Experimental.

Icon Moving remains explicit user action only. It requires Pro Mode, Accessibility Discovery, Accessibility permission, the Icon Moving feature toggle, and user confirmation. It does not use private APIs, screenshots, Screen Recording, ScreenCaptureKit, network access, or background automation.

## Implemented

- Move planning and guarded move service.
- Settings gates for enablement, confirmation, retry count, drag duration, and system-item allowance.
- Find Icon and Second Bar expose experimental move actions only through explicit user interaction.
- Private Access protects Icon Moving by default.
- Unit tests cover planning and selected failure cases.

## Deferred

- Command Center executor for experimental activation/move commands.
- Full recovery UI after failed moves.
- Manual QA for real Command-drag behavior across menu bar layouts.

