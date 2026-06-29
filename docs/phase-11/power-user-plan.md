# Phase 11 Power User Plan

## Scope

The power-user pack adds organization and automation surfaces without changing
the Basic Mode permission boundary.

## Features

- Icon Groups for user-managed collections.
- Group panels for keyboard browsing and conservative activation.
- Dynamic hotkeys for groups, profiles, layout, and automation actions.
- App Intents for Shortcuts automation.
- Import/export for settings, groups, spacers, hotkeys, and profile packs.

## Defaults

- Groups are enabled, but group status items are off by default.
- Dynamic hotkeys are off by default.
- Private Access is off by default.
- Profile apply from App Intents is off by default.
- Labs access from App Intents is off by default.

## Guardrails

- No Apple Events or AppleScript dictionary.
- No automatic third-party icon movement from groups, profiles, imports, or
  shortcuts.
- Dynamic hotkeys respect conflicts, Safe Mode, Pro requirements, and Private
  Access.
- Imports dry-run first and create a backup before apply.

## Degraded States

- Missing Pro data: group matching falls back to manual refs and bundle IDs.
- Protected action locked: hotkey/intent returns a privacy-safe denied result.
- Safe Mode active: optional power-user automation is disabled.
