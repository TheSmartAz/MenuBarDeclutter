# Shortcuts v0.1.3

Status: Preview.

v0.1.3 exposes basic app actions through App Intents and Shortcuts while keeping advanced actions gated.

## Basic Actions

The basic action surface includes:

- Expand Menu Bar Items
- Collapse Menu Bar Items
- Toggle Menu Bar Items
- Reveal All Menu Bar Items
- Show Find Icon

Basic visibility actions do not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

## Gated Actions

Advanced actions fail closed or report gated status when required features are unavailable:

- Show Find Icon requires the Find Icon feature and Pro Discovery gates when metadata is needed.
- Show Second Bar requires Pro Discovery gates.
- Apply Profile requires profile automation gates.
- Labs actions require Labs access gates.
- Assisted Move remains Experimental and confirmation-gated.

## Privacy

Shortcuts run local app commands. They do not add telemetry, cloud sync, network access, Apple Events control of other apps, Screen Recording, or Input Monitoring.

## Verification

- `AppIntentExecutionServiceTests`
- `MenuBarCommandRouterTests`
- `docs/testing/manual-qa.md`
