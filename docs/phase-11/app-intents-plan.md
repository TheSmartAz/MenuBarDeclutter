# Phase 11 App Intents Plan

## Intent Surface

App Intents expose app-owned actions for Shortcuts:

- Expand and collapse the app separator.
- Reveal all temporarily.
- Open or close Second Bar.
- Enter or exit Full Menu Bar Mode.
- Apply profiles when enabled.
- Pause or resume automation.
- Open Settings and Diagnostics.

## Permission Boundary

The Shortcuts surface does not add Apple Events, Input Monitoring, Screen
Recording, network, telemetry, or cloud sync. Intents call the same internal
services used by Settings and the status menu.

## Gating

- App Intents master toggle must be enabled.
- Profile apply requires `appIntentsCanApplyProfiles`.
- Labs actions require `appIntentsCanAccessLabs`.
- Private Access protected actions must be unlocked.
- Safe Mode allows only safe commands such as Settings, Diagnostics, and reset.
- Automation pause blocks automation-style actions.

## Result Policy

Results should be short, generic, and privacy-safe. Do not include protected
group names, protected item names, file paths, or live search text.

## QA Focus

- Toggle App Intents off and confirm commands degrade.
- Test profile apply disabled/enabled.
- Test Labs access disabled/enabled.
- Test Safe Mode and Private Access denial paths.
