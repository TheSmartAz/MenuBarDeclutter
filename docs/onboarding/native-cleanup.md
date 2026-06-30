# Native Cleanup Onboarding

`v0.1.1` teaches users that Apple's Menu Bar and Control Center settings are complementary to MenuBarDeclutter.

Implemented onboarding copy:

- Title: Start with Apple's Menu Bar settings
- Body: Move rarely-used system controls into Control Center first. MenuBarDeclutter then helps with third-party and crowded menu bar workflows.
- Button: Open Menu Bar Settings

Implementation behavior:

- Tries the Control Center / Menu Bar System Settings deep link first.
- Falls back to opening System Settings.
- Do not require permissions.
- Do not automate system setting changes.
- Do not claim MenuBarDeclutter replaces Apple's settings.

Coverage:

- `MenuBar-Manager/Onboarding/OnboardingStep.swift`
- `MenuBar-Manager/Onboarding/OnboardingRootView.swift`
- `MenuBar-Manager/Onboarding/OnboardingSystemSettingsOpener.swift`
- `MenuBar-ManagerTests/OnboardingStepTests.swift`
