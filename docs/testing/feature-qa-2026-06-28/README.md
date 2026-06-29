# Feature QA Run - 2026-06-28

Scope: feature verification against `docs/features/` for `MenuBarDeclutter`.

Environment:

- macOS: local Mac, Xcode SDK `MacOSX26.2.sdk`
- App under test: Debug `MenuBarDeclutter.app` from DerivedData
- Test defaults: `--ui-testing` suite where available, so personal app settings were not modified
- Screenshots: `docs/testing/feature-qa-2026-06-28/screenshots/`

## Commands

- `xcodebuild -list` - passed; canonical scheme `MenuBarDeclutter` and fixture scheme `MenuBarFixtureApp` present.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` - passed.
  - Unit test summary: 215 tests in 37 suites passed.
  - UI test summary: 7 tests passed.
  - Result bundle: `/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.28_22-06-00--0700.xcresult`
- `scripts/qa_build_fixture.sh` - passed; `MenuBarFixtureApp` build succeeded.
- `APP_PATH=/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` - passed.
- Follow-up fix verification:
  - `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/OnboardingStepTests` - passed; 4 Swift Testing tests passed.
  - `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` - passed; 215 unit tests and 7 UI tests passed.

## Finding

| ID | Severity | Feature | Result | Evidence |
| --- | --- | --- | --- | --- |
| FQA-001 | P2 | Onboarding | Fixed. The Hotkey & Auto-Rehide onboarding page now says Auto-Rehide is off by default, matching v0.1 safe defaults and the Behavior page. | Original mismatch: `screenshots/21-onboarding-04-hotkey-auto-rehide-mismatch.png`; fixed screenshot: `screenshots/31-onboarding-04-hotkey-auto-rehide-fixed.png`; source `MenuBar-Manager/Onboarding/OnboardingStep.swift:49`; defaults `MenuBar-Manager/Core/SettingsStore.swift:129`; feature spec `docs/features/basic-behavior-controls.md:50` |

## Feature Matrix

| Feature doc | Outcome | Notes / screenshots |
| --- | --- | --- |
| `basic-mode-hiding.md` | Partial pass | Two status items are installed and exposed as `MenuBarDeclutter control` and `Hidden items separator`; pure logic/menu builder tests passed. Real Command-drag/display/notch/Spaces behavior still needs hands-on manual QA. Screens: `24-status-items-visible.png`, `25-status-menu-right-click-attempt-blocked.png`. |
| `basic-behavior-controls.md` | Pass with manual gaps | Behavior page safe defaults match spec: auto-rehide off, hover off, always-hidden off, hotkey off. Unit tests cover rehide, hover, hotkeys, and visibility state. Real pointer hover/global hotkey manual behavior was not mutated. Screen: `02-settings-behavior.png`. |
| `settings-onboarding-and-resets.md` | Pass | Settings sections exist; General shows launch/login, reset, onboarding, version/bundle surfaces. Onboarding replay works and all six pages were captured. FQA-001 was fixed and visually rechecked. Screen set: `01`, `18`-`23`, `31`. |
| `launch-at-login.md` | UI/test pass; installed login cycle not executed | General page shows toggle, live SMAppService status, current bundle path, and DerivedData warning. Unit tests passed. I did not register/unregister Login Items on the real system. Screen: `01-settings-general.png`. |
| `privacy-pro-mode-accessibility-discovery.md` | Pass | Basic Mode lists sensitive permissions as not requested/not used. Pro Mode opt-in enables AX discovery controls without prompting. Manual AX scan with no permission degrades to zero items/not requested. Privacy script passed. Screens: `11`, `12`, `13`. |
| `find-icon.md` | Pass for unavailable states; real results blocked by AX permission | Floating panel opens, disabled state is clear, enabling progresses through Pro Required to Accessibility Permission Needed. No clicking automation. Screens: `26`, `27`, `28`. |
| `second-bar.md` | Pass for settings and unavailable panel states; real item listing blocked by AX permission | Settings controls/requirements visible; panel opens and progresses from Pro Required to Accessibility Permission Needed. Screens: `04`, `05`, `29`, `30`. |
| `profiles.md` | Pass | Created a local QA profile, editor showed expected fields, Dry Run reported conservative reveal actions/no moves, Apply saved/applied Basic settings, Diagnostics logged it. Screens: `06`, `07`, `08`, `09`. |
| `smart-triggers.md` | Pass for local configuration/paused behavior | Added a display-count trigger to the QA profile. Automation remained paused and did not apply profiles. Unit tests cover evaluator/service/persistence. Screen: `10-settings-profiles-trigger-paused.png`. |
| `diagnostics-and-export.md` | Pass with UI capture limitation | Diagnostics shows health controls, filters/export controls in accessibility tree, live status, AX degraded state, profile/trigger logs, screen frame metadata, Dogfood controls. Diagnostics export is covered by unit tests; I did not drive the NSSavePanel manually. Screens: `13`, `14`, `15`. |
| `health-recovery-safe-mode.md` | Pass for visible controls/tests; real restart/crash flows not executed | Diagnostics showed Health warning when Pro discovery lacked AX permission, plus Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch controls. Unit tests passed. Screen: `13`. |
| `dogfood-qa-mode.md` | Pass | Dogfood Mode enabled, run started with local run ID, Gate A checklist was exposed, fixture app build succeeded. Screens: `14`, `15`. |
| `experimental-icon-moving.md` | Pass for gate/warning/tests; real drag not executed | Advanced page keeps icon moving off by default. First-use warning appeared and Cancel preserved safe state. Unit tests cover planning/safety. Real CGEvent move requires AX permission and live menu bar targets. Screens: `16`, `17`. |
| `url-automation.md` | Pass by tests/static verification; runtime URL not sent | `menubardeclutter://` scheme verified by privacy script and automation handler tests passed. I did not open live URLs because an installed app with the same bundle ID was also running and could receive the command. |

## Screenshot Index

- `01-settings-general.png`
- `02-settings-behavior.png`
- `03-settings-search.png`
- `04-settings-second-bar-top.png`
- `05-settings-second-bar-requirements.png`
- `06-settings-profiles-empty.png`
- `07-settings-profiles-editor-created.png`
- `08-settings-profiles-dry-run.png`
- `09-settings-profiles-applied.png`
- `10-settings-profiles-trigger-paused.png`
- `11-settings-privacy-basic-pro-disabled.png`
- `12-settings-privacy-pro-enabled-permission-not-requested.png`
- `13-settings-diagnostics-live-status.png`
- `14-settings-diagnostics-dogfood-run.png`
- `15-settings-diagnostics-gate-a-tree-verified.png`
- `16-settings-advanced.png`
- `17-settings-advanced-icon-moving-warning.png`
- `18-onboarding-01-welcome.png`
- `19-onboarding-02-command-drag.png`
- `20-onboarding-03-hidden-vs-always-hidden.png`
- `21-onboarding-04-hotkey-auto-rehide-mismatch.png`
- `22-onboarding-05-privacy.png`
- `23-onboarding-06-macos26-note.png`
- `24-status-items-visible.png`
- `25-status-menu-right-click-attempt-blocked.png`
- `26-find-icon-disabled-panel.png`
- `27-find-icon-pro-required-panel.png`
- `28-find-icon-accessibility-needed-panel.png`
- `29-second-bar-pro-required-panel.png`
- `30-second-bar-accessibility-needed-panel.png`
- `31-onboarding-04-hotkey-auto-rehide-fixed.png`

## Not Executed

- Granting/revoking Accessibility permission in System Settings.
- Registering/unregistering Launch at Login on the real system.
- Sending `menubardeclutter://` runtime URLs, because another installed app instance with the same bundle ID was running.
- Real Command-drag separator placement, external display/notch/Spaces/sleep-wake checks, real hover polling, and real global hotkey presses.
- Real icon movement with CGEvent drag.
