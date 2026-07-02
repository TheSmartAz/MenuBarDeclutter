# Smart Triggers

Smart Triggers are optional local automation rules that apply profiles from local system signals. They are disabled by default, and global automation is paused by default in v0.1.

## What It Does

- Stores trigger JSON under Application Support.
- Supports rules for display count, app launched, frontmost app, battery low, and time of day from the current UI.
- Models Focus and Wi-Fi rules for future safe providers, but runtime providers are inactive today.
- Observes display changes, app launches, frontmost app changes, a one-minute timer, and public battery capacity where available.
- Debounces event bursts.
- Uses first-match trigger precedence.
- Avoids profile loops.
- Applies profiles through Command Center so profile gates, Safe Mode, and Private Access outcomes stay consistent with other profile automation paths.
- Exposes Pause All Automation in Advanced and the status menu.

## User Flow

1. Open Settings -> Advanced -> Profiles.
2. Create at least one profile.
3. Add a trigger for the selected profile.
4. Enable smart triggers.
5. Resume automation if global automation is paused.
6. Watch Diagnostics for trigger evaluation and last fired state.

## Privacy And Permissions

Smart Triggers use local public system signals. They do not use network access, telemetry, cloud sync, Apple Events scripting dictionaries, Screen Recording, Input Monitoring, or hidden bulk icon movement. Global automation pause stops trigger observers/evaluation.

## Implementation

- `MenuBar-Manager/Profiles/TriggerModel.swift`
- `MenuBar-Manager/Profiles/TriggerRuleEvaluator.swift`
- `MenuBar-Manager/Profiles/TriggerService.swift`
- `MenuBar-Manager/Profiles/ProfileAutomationCoordinator.swift`
- `MenuBar-Manager/Profiles/ProfileListView.swift`

## Verification

- `MenuBar-ManagerTests/TriggerRuleEvaluatorTests.swift`
- `MenuBar-ManagerTests/TriggerServiceTests.swift`
- `MenuBar-ManagerTests/TriggerServicePersistenceTests.swift`
- Manual QA: `docs/testing/manual-v0.1.3-system-qa.md`

## Known Limitations

- Smart Triggers are disabled by default and automation is paused by default.
- Focus and Wi-Fi rules remain model placeholders until safe runtime providers are added.
- Real display/app/battery/time event behavior still needs hands-on dogfood.
