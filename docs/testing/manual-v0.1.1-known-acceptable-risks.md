# Manual v0.1.1 Known Acceptable Risks

- Dry-run artifacts are not notarized; Gatekeeper and stapler warnings are expected for dry-run builds.
- Icon Moving is Experimental and can fail on system items or third-party items that do not behave like normal command-draggable menu bar items.
- Pro metadata can be incomplete when apps expose sparse Accessibility attributes.
- Second Bar and Find Icon can only be as accurate as the latest Accessibility snapshot.
- Import/export migration assistant remains Preview/Dry-run unless a later phase completes apply semantics.
- Exported settings packages intentionally omit volatile/private local state such as permission status, authentication status, dogfood run IDs, backup/apply state, and the deprecated primary separator setting.
- Menu Bar Spacing Labs must remain explicit and should not automatically apply global defaults.
- Manual QA still needs real notch/external-display coverage before broad public distribution.

Not acceptable for `v0.1.1`:

- Basic Mode requiring Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, or Pro Mode.
- Any automatic Accessibility prompt.
- Any ScreenCaptureKit linkage or Screen Recording usage string.
- Any release UI or docs claiming Icon Moving, Spacing Labs, Smart Triggers, App Intents, Private Access, or Import/Export migration is Stable.
- Any real settings export containing synthetic marker values instead of real or intentionally omitted values.
