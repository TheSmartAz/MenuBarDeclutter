# Command Center v0.1.1

Status: Preview.

Command Center is the shared command/result path for advanced MenuBarDeclutter actions in the `v0.1.1` line. It is implemented in `MenuBar-Manager/CommandCenter/` and is used by App Intents, URL automation, Dynamic Hotkeys, Find Icon item actions, Second Bar item actions, selected group actions, profile automation, and advanced status-menu actions.

## Implemented

- Structured commands, targets, result statuses, availability summaries, and privacy-safe diagnostics.
- Gates for Safe Mode, automation pause, App Intents enablement, Pro Mode, Accessibility Discovery, Accessibility permission, feature flags, Labs, Private Access, experimental confirmation, and target shape.
- Private Access can now protect profile apply and automation commands when the user enables those toggles.
- Diagnostics log action/source/target kind/status/reason without live queries, item IDs, protected names, or full paths.

## Deferred

- A dedicated Command Center UI/view model.
- Central stale-scan and target-existence validation before handler execution.
- Executors for remove-from-group, assign-hotkey, protect-resource, unlock-protected-action, and experimental activation commands.

