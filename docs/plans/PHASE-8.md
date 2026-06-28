Implement Phase 8 — Profiles, Smart Triggers, Automation.

Context:
The app now has Basic Mode and Pro Mode capabilities. Add profiles and smart triggers, but keep them conservative and user-controlled.

Tasks:

1. Profiles module.
   Create:
   - Profiles/ProfileModel.swift
   - Profiles/ProfileStore.swift
   - Profiles/ProfileApplicationService.swift
   - Profiles/ProfileEditorView.swift
   - Profiles/ProfileListView.swift

2. Profile model.
   Profile fields:
   - id
   - name
   - createdAt
   - updatedAt
   - preferredVisibilityState
   - showSecondBar
   - autoRehideEnabled
   - hoverRevealEnabled
   - targetZonesByBundleID
   - notes

   Store as JSON in Application Support.

3. Profile UI.
   Settings > Profiles:
   - list profiles.
   - create profile.
   - duplicate profile.
   - delete profile.
   - apply profile.
   - export/import profile JSON.

4. Applying profile.
   ProfileApplicationService:
   - applies Basic settings immediately.
   - applies visibility state.
   - Pro zone moves require confirmation unless user explicitly allows.
   - Never silently run mass CGEvent moves.
   - Provide dry-run summary:
     - items to reveal.
     - items to move.
     - unavailable items.
     - permission requirements.

5. Trigger module.
   Create:
   - Profiles/TriggerModel.swift
   - Profiles/TriggerService.swift
   - Profiles/TriggerRuleEvaluator.swift

6. Trigger types.
   Implement safe triggers first:
   - external display connected.
   - specific app launched/frontmost.
   - battery low.
   - time of day.
   - focus mode placeholder if reliable API exists.
   - Wi-Fi SSID optional, only if public API works on macOS 26+.

7. Trigger behavior.
   - User must create trigger explicitly.
   - Trigger applies selected profile.
   - Show notification or menu bar feedback when profile changes.
   - Debounce triggers.
   - Avoid loops.
   - Maintain last applied profile.

8. Automation.
   Add AppleScript/Shortcuts-friendly minimal commands only if practical:
   - apply profile by name.
   - expand.
   - collapse.
   - reveal all.
   - show second bar.

   If AppleScript dictionary is too large for this phase, create docs/automation-roadmap.md and implement URL scheme instead:
   - menubardeclutter://expand
   - menubardeclutter://collapse
   - menubardeclutter://profile/Work

9. Settings.
   Add:
   - enable smart triggers.
   - trigger list.
   - profile list.
   - import/export.
   - dry-run apply profile.

10. Diagnostics.
   Show:
   - active profile.
   - last trigger fired.
   - trigger evaluation logs.
   - profile apply logs.

11. Tests.
   Add:
   - ProfileStoreTests.
   - TriggerRuleEvaluatorTests.
   - ProfileApplicationDryRunTests.

   Test:
   - profile save/load.
   - import/export.
   - trigger matching.
   - debounce.
   - dry-run warnings.

12. Manual QA.
   Add:
   - create profile.
   - apply profile.
   - export/import.
   - external display trigger.
   - app launch trigger.
   - battery trigger if practical.
   - disable triggers.
   - verify no automatic drag without confirmation.

Acceptance criteria:
- User can create/apply profiles.
- User can configure basic smart triggers.
- Triggers are debounced and safe.
- Profile application has dry-run summary.
- No automatic icon moving unless explicitly allowed.
- Basic Mode remains stable.

Out of scope:
- No cloud sync.
- No team/shared profiles.
- No aggressive AI layout optimization.