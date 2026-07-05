Implement Phase 3 — Settings, Onboarding, Launch at Login, Diagnostics, Packaging.

Context:
Phase 1/2 created a working permission-free menu bar hiding app. Now polish Basic Mode into a stable macOS 26+ utility.

Tasks:

1. Full Settings UI.
   Create/modify:
   - Settings/SettingsWindowController.swift
   - Settings/SettingsRootView.swift
   - Settings/GeneralSettingsView.swift
   - Settings/BehaviorSettingsView.swift
   - Settings/PrivacySettingsView.swift
   - Settings/DiagnosticsSettingsView.swift
   - Settings/AdvancedSettingsView.swift

   General:
   - Launch at Login
   - Start collapsed
   - Show separators
   - Reset app layout
   - Reset all settings
   - App version
   - Build number

   Behavior:
   - Auto-rehide
   - Auto-rehide delay
   - Hover reveal
   - Always-hidden section
   - Hotkey enable/disable
   - Option-click reveal all

   Privacy:
   - Basic Mode requires no Accessibility.
   - Basic Mode requires no Screen Recording.
   - Basic Mode does not need network access.
   - Pro Mode permissions will only be requested after explicit opt-in.

   Diagnostics:
   - Current state.
   - Current screens.
   - Current separator lengths.
   - Hotkey status.
   - Last 200 logs.
   - Export diagnostics.

2. Onboarding.
   Create:
   - Onboarding/OnboardingWindowController.swift
   - Onboarding/OnboardingRootView.swift
   - Onboarding/OnboardingStep.swift

   First-run steps:
   - What the app does.
   - How to Command-drag icons and separators.
   - Hidden vs always-hidden.
   - Hotkey and auto-rehide.
   - Privacy: no sensitive permissions in Basic Mode.
   - macOS 26 visual note: transparent menu bar may make separators less visible; user can adjust separator visibility.

   Add:
   - Show onboarding again from Settings.
   - hasCompletedOnboarding setting.

3. Launch at Login.
   Create:
   - Core/LaunchAtLoginService.swift

   Requirements:
   - Use SMAppService.mainApp.
   - register() when user enables.
   - unregister() when user disables.
   - expose current status.
   - show error in diagnostics.
   - do not auto-enable without user action.

4. Diagnostics export.
   Extend DiagnosticsLogger:
   - export as .txt or .json.
   - include:
     - app version.
     - macOS version.
     - machine architecture.
     - screen count and frames.
     - current settings.
     - recent logs.
   - exclude:
     - screenshots.
     - screen contents.
     - personal file paths except app support path if necessary.
     - network data.

5. App Support.
   Create/extend:
   - Core/AppSupportPaths.swift

   Paths:
   - Application Support/MenuBarDeclutter/
   - diagnostics/
   - profiles/ for future phase
   - backups/ for future phase

6. macOS 26 styling.
   Update SwiftUI settings:
   - support light/dark.
   - support increased contrast.
   - support reduce transparency.
   - avoid custom transparent effects that conflict with Liquid Glass.
   - keep controls readable over transparent menu bar context.

7. Release scripts.
   Update:
   - scripts/build_debug.sh
   - scripts/build_release.sh
   - scripts/test.sh
   - scripts/notarize_template.sh
   - docs/release-checklist.md

   Release checklist:
   - clean build.
   - run tests.
   - manual QA.
   - archive.
   - export.
   - codesign verification.
   - notarization template.
   - stapler validation.
   - zip/dmg placeholder.

8. Architecture docs.
   Update:
   - docs/architecture/architecture-overview.md
   - docs/PLAN.md

   Document:
   - Basic Mode architecture.
   - Why we do not request permissions yet.
   - Phase 4 Pro Mode boundary.

9. Tests.
   Add:
   - SettingsStoreTests for all settings.
   - DiagnosticsExportTests.
   - LaunchAtLoginService mock tests if practical.
   - AppSupportPathsTests.

10. Manual QA.
   Update:
   - first launch onboarding.
   - settings persistence.
   - launch at login.
   - diagnostics export.
   - reset settings.
   - quit/relaunch.
   - restart macOS if possible.
   - transparent menu bar.
   - show menu bar background enabled.
   - reduce transparency.
   - increase contrast.
   - external display.

Acceptance criteria:
- First-run onboarding appears once.
- Settings window is complete.
- Launch at Login toggle works using SMAppService.
- Diagnostics export works.
- App can be built for release.
- No sensitive permission prompt appears.
- Basic Mode is stable enough for daily use.

Out of scope:
- No Accessibility scanning.
- No search.
- No second bar.
- No icon moving.