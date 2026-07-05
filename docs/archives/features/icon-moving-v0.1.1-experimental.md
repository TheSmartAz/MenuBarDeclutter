# Icon Moving v0.1.1

Status: Experimental.

Icon Moving remains explicit user action only. It requires Pro Mode, Accessibility Discovery, Accessibility permission, the Icon Moving feature toggle, first-use confirmation, and per-move confirmation. It does not use private APIs, screenshots, Screen Recording, ScreenCaptureKit, network access, or background automation.

## Implemented

- Move planning and guarded move service.
- Settings gates for enablement, confirmation, retry count, drag duration, and system-item allowance.
- Find Icon and Second Bar expose experimental move actions only through explicit user interaction.
- Arrange exposes the Assisted Move dry-run, confirmation, result, and recovery subflow.
- Private Access protects Icon Moving by default.
- Unit tests cover planning and selected failure cases.

## Remaining Work

- Live execution for Command Center try-assisted-move beyond the current dry-run/gate vocabulary.
- Manual QA for real Command-drag behavior across menu bar layouts.
