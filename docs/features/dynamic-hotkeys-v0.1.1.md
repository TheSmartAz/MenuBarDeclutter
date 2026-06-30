# Dynamic Hotkeys v0.1.1

Status: Preview.

Dynamic Hotkeys bind local keyboard shortcuts to selected MenuBarDeclutter actions. They are disabled by default and respect Safe Mode.

## Implemented

- Binding store, registration service, conflict detection for duplicate local bindings, and Settings UI.
- Routed execution through Command Center for reveal/highlight item, open group, reveal group, show Second Bar filtered to group/item, apply profile, Full Menu Bar Mode, and automation pause/resume.
- Protected profile/group actions use the same Private Access gate when configured.
- Diagnostics report counts and registration status without protected target names.

## Deferred

- Bindings for every Phase 13 target type, including expand/collapse/toggle, show Find Icon, show Icon Panel, open owning app, protected command, and experimental activation.
- Reserved system-combo detection beyond current local conflict checks.
- Schema-version field in the hotkey container.

