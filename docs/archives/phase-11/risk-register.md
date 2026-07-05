# Phase 11 Risk Register

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Private Access mistaken for encryption | Users may over-trust protection | Document that it gates app UI only and stores no encrypted vault |
| Group names reveal sensitive context | Privacy leak in UI/logs | Redact protected group names in protected surfaces and diagnostics |
| Dynamic hotkey conflict | Wrong action or failed registration | Detect conflicts, skip conflicting bindings, show Settings warning |
| Safe Mode still runs automation | Recovery becomes noisy | Unregister dynamic hotkeys, disable group status items, keep Settings/Diagnostics |
| Import enables experimental features silently | Unexpected behavior | Dry-run risky flags and require explicit experimental import |
| Shortcuts bypass protected actions | Privacy boundary break | Route intents through execution service and ProtectedActionGate |
| Pro data unavailable | Group matching or item hotkeys fail | Degrade to manual/bundle refs and explain unavailable state |
| Status item clutter from groups | Worse menu bar crowding | Group status items are opt-in and can be disabled in Safe Mode |

## Open Follow-ups

- Add more UI automation coverage around panels once stable accessibility
  identifiers are available.
- Add richer App Intent dialog strings if framework limitations allow dynamic
  text safely.
