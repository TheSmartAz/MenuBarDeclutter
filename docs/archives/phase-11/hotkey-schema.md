# Phase 11 Hotkey Schema

## Store

Dynamic hotkeys are stored locally as `hotkeys.json` through
`HotkeyBindingStore`.

```json
{
  "bindings": []
}
```

## HotkeyBinding

```json
{
  "id": "UUID",
  "action": {
    "kind": "openGroup",
    "uuidValue": "UUID"
  },
  "keyCode": 11,
  "modifiersRaw": 2304,
  "isEnabled": true,
  "label": "Open Group",
  "createdAt": "date",
  "updatedAt": "date"
}
```

## Action Kinds

- `revealAndHighlightItem` with `stringValue`.
- `openGroup` with `uuidValue`.
- `openSecondBarFilteredToGroup` with `uuidValue`.
- `openSecondBarFilteredToItem` with `stringValue`.
- `applyProfile` with `uuidValue`.
- `enterFullMenuBarMode`.
- `exitFullMenuBarMode`.
- `pauseAutomation`.
- `resumeAutomation`.

## Runtime Rules

- Dynamic hotkeys are disabled by default.
- Conflicting enabled bindings are not registered.
- Protected targets are gated by Private Access.
- Pro-only item actions degrade when Pro data is unavailable.
- Safe Mode unregisters dynamic hotkeys.

## Diagnostics

Diagnostics export setting flags and counts only. Protected hotkey target
identity must remain redacted.
