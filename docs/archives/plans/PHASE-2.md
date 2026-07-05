Implement Phase 2 — Basic UX Polish: Hotkey, Auto-Rehide, Hover Reveal, Always-Hidden Zone.

Context:
Phase 1 implemented separator-based hiding. Now add daily-use behavior while keeping Basic Mode permission-free.

Hard rule:
Do not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Tasks:

1. Extend SettingsStore.
   Add:
   - autoRehideEnabled: Bool default true
   - autoRehideDelaySeconds: Double default 5
   - hoverRevealEnabled: Bool default false
   - hoverRevealPollingIntervalSeconds: Double default 0.25
   - alwaysHiddenEnabled: Bool default false
   - showSeparators: Bool default true
   - globalHotkeyEnabled: Bool default false
   - globalHotkeyKeyCode: Int?
   - globalHotkeyModifiersRaw: UInt?
   - revealAllOnOptionClick: Bool default true

2. Global hotkey.
   Create:
   - Hotkeys/GlobalHotkeyManager.swift
   - Hotkeys/HotkeyModel.swift

   Preferred:
   - Use Carbon RegisterEventHotKey.
   - No third-party hotkey package yet.
   - Default hotkey: Option + Command + B.
   - Register/unregister based on setting.
   - Log conflicts/failures.
   - Failure must not crash app.

3. Rehide controller.
   Create:
   - Hiding/RehideController.swift

   Behavior:
   - When user expands hidden items, start one-shot auto-rehide timer.
   - If mouse is in menu bar band, postpone.
   - If settings window is key, postpone.
   - If status item menu is open, postpone.
   - If user manually collapses, cancel timer.
   - Log last rehide reason.

4. Hover reveal.
   Implement using timer polling:
   - Check NSEvent.mouseLocation.
   - If mouse enters any menu bar band and state is collapsed, expand.
   - If mouse leaves and autoRehideEnabled is true, schedule rehide.
   - Do not use event taps.

5. Always-hidden section.
   Add:
   - alwaysHiddenSeparatorItem: NSStatusItem
   - deep separator controller support.

   States:
   - collapsed:
     - primary separator collapsed
     - always-hidden separator collapsed
   - expanded:
     - primary separator expanded
     - always-hidden separator collapsed
   - revealAll:
     - primary separator expanded
     - always-hidden separator expanded

   Create enum:
   - HidingVisibilityState
     - collapsed
     - expanded
     - revealAll

6. Option-click behavior.
   - Normal click toggles collapsed/expanded.
   - Option-click toggles revealAll if setting enabled.
   - Menu item also exposes Reveal All.

7. Separator visuals.
   - showSeparators setting hides/shows separator button title/image.
   - Do not remove the separator items; only hide their visual marker.

8. Settings UI.
   Update BehaviorSettingsView:
   - Auto-rehide toggle.
   - Delay slider/field.
   - Hover reveal toggle.
   - Always-hidden toggle.
   - Show separators toggle.
   - Global hotkey enable toggle.
   - Current hotkey display.
   - Reveal all with Option-click toggle.

9. Diagnostics.
   Show:
   - current visibility state.
   - primary separator length.
   - always-hidden separator length.
   - hotkey registered.
   - hover polling active.
   - auto-rehide scheduled.
   - last rehide reason.

10. Tests.
   Add:
   - RehideControllerTests if timer can be injected.
   - HidingStateTests.
   - HotkeyModelTests.
   - ScreenGeometry point-in-menu-bar tests.

   Test:
   - collapsed / expanded / revealAll length mapping.
   - settings defaults.
   - delay validation clamps invalid values.

11. Manual QA.
   Update:
   - hotkey toggle.
   - auto-rehide.
   - hover reveal.
   - always-hidden separator.
   - Option-click reveal all.
   - show/hide separators.
   - transparent menu bar mode.
   - external display.
   - notch display if available.

Acceptance criteria:
- Hotkey toggles visibility.
- Auto-rehide works.
- Auto-rehide does not collapse while user is interacting with menu bar.
- Hover reveal works without permissions.
- Always-hidden zone works.
- Option-click reveal all works.
- Settings persist after restart.
- No sensitive permission prompt appears.

Out of scope:
- No Accessibility item discovery.
- No search.
- No second bar.
- No programmatic moving.