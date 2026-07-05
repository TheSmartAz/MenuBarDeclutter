
## Phase 9.1 — Alpha RC Validation + Release Hardening

```text
Implement Phase 9.1 — Alpha RC Validation + Release Hardening.

Context:
Phases 0–9 are implemented for MenuBarDeclutter. Phase 10 ScreenCaptureKit visual capture is intentionally postponed. The app targets macOS 26.0+ only and is built with Swift + AppKit + SwiftUI.

Current known status:
- Product display name is MenuBarDeclutter.
- Xcode project and active scheme are still MenuBar-Manager.
- Basic Mode is usable without sensitive permissions.
- Pro Mode is opt-in and depends on Accessibility.
- Latest recorded xcodebuild test passed on 2026-06-28.
- Hands-on QA is still required for real Command-drag separator placement, icon moving, external display/notch behavior, Launch at Login, Accessibility grant/revoke, and network monitoring.

Phase goal:
Do not add major new features. Freeze the feature set, validate real macOS behavior, harden risky surfaces, clean release identity, and prepare an Alpha RC build.

Hard constraints:
1. Do not implement Phase 10.
2. Do not add ScreenCaptureKit.
3. Do not add Screen Recording permission.
4. Do not add Apple Events.
5. Do not add Input Monitoring.
6. Do not add network access.
7. Keep Basic Mode fully usable without Accessibility.
8. Keep Pro Mode opt-in.
9. Keep icon moving disabled by default.
10. Prefer hardening, diagnostics, tests, and QA docs over new features.
11. Every code change should have a clear release-hardening purpose.
```

---

## Task 1 — Repository and build-status audit

```text
Inspect the repository and produce an implementation status report.

Run:
- ls
- find . -maxdepth 4 -type f | sort
- xcodebuild -list
- xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'

Create or update:
- docs/status/phase-9.1-audit.md

The audit should include:
1. Current schemes.
2. Current app target names.
3. Current bundle identifiers.
4. Current product names.
5. Current deployment target.
6. Current entitlements.
7. Current Info.plist keys.
8. Whether LSUIElement is set.
9. Whether URL scheme is registered.
10. Whether app sandbox is enabled.
11. Whether network entitlements exist.
12. Whether ScreenCaptureKit or Screen Recording strings exist.
13. Whether Accessibility usage is only Pro Mode gated.
14. Current test result.
15. Current manual QA docs available.
```

Acceptance criteria:

```text
- Audit doc exists.
- Build/test result is recorded.
- Any mismatch is listed as an actionable issue.
```

---

## Task 2 — Product identity cleanup

```text
Clean up product identity for alpha release.

Problem:
Product display name is MenuBarDeclutter, but the Xcode project and active scheme are still MenuBar-Manager.

Implement the safest version:
1. Create a shared scheme named MenuBarDeclutter.
2. Keep MenuBar-Manager temporarily if removing it is risky.
3. Update scripts to prefer MenuBarDeclutter.
4. Keep backwards compatibility in docs by mentioning the old scheme as deprecated.
5. Ensure product display name remains MenuBarDeclutter.
6. Ensure app support directory remains MenuBarDeclutter.
7. Ensure diagnostics export says MenuBarDeclutter.
8. Ensure URL scheme remains menubardeclutter://.
9. Update docs and manual QA commands.

Files likely affected:
- .xcodeproj/xcshareddata/xcschemes/
- scripts/build_debug.sh
- scripts/build_release.sh
- scripts/test.sh
- scripts/notarize_template.sh
- docs/PLAN.md
- docs/release-checklist.md
- docs/testing/manual-qa.md
- docs/status/phase-9.1-audit.md
```

Acceptance criteria:

```text
- xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build passes.
- xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' passes.
- Existing MenuBar-Manager scheme either still works or is clearly deprecated.
- Docs use MenuBarDeclutter as the canonical scheme.
```

---

## Task 3 — Entitlements and privacy boundary verification

```text
Add a privacy/entitlements verification pass.

Create:
- scripts/verify_privacy_boundary.sh
- docs/privacy/privacy-boundary.md
- docs/testing/privacy-qa.md

The script should check the built app or project files for:
1. No network entitlements.
2. No ScreenCaptureKit imports unless explicitly allowed in future.
3. No NSScreenCaptureUsageDescription or equivalent screen recording usage string.
4. No Apple Events usage description.
5. No Input Monitoring usage description.
6. Accessibility references are present only because Pro Mode uses AX APIs.
7. URL scheme is local and command-limited.
8. App Support paths are local.
9. Diagnostics export excludes screenshots and live query identity.

The docs should explain:
- Basic Mode requires no sensitive permissions.
- Pro Mode requires Accessibility only after explicit user action.
- Icon moving is Pro-only and user-triggered.
- Second Bar uses app/bundle icons and AX metadata, not screen capture.
- Profiles/triggers are local JSON.
- URL automation is local and limited.
- No telemetry or cloud sync exists.
```

Acceptance criteria:

```text
- Privacy verification script exists.
- Privacy docs match the actual implementation.
- Any mismatch fails loudly or is documented as a blocking alpha issue.
```

---

## Task 4 — Mark risky Pro features as Experimental

```text
Make risky Pro features visibly experimental for Alpha.

Risky features:
1. Programmatic icon moving.
2. Smart triggers that automatically apply profiles.
3. Any trigger that depends on partially implemented providers.
4. Any future profile behavior that could move icons.

Implement:
- Add a Labs/Experimental label in Settings -> Advanced.
- Keep icon moving disabled by default.
- Add visible warning before enabling icon moving.
- Add clear copy:
  “Experimental: uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps.”
- Smart triggers should be opt-in and easy to pause globally.
- Add one global “Pause All Automation” setting.
- Add menu item: Pause Automation / Resume Automation.
- Diagnostics should show whether experimental features are enabled.

Files likely affected:
- Settings/AdvancedSettingsView.swift
- Settings/ProfilesSettingsView.swift
- Settings/DiagnosticsSettingsView.swift
- Moving/IconMoveService.swift
- Profiles/TriggerService.swift
- Core/SettingsStore.swift
- StatusBar/StatusBarMenuBuilder.swift
```

Acceptance criteria:

```text
- Icon moving is clearly experimental.
- Icon moving remains off by default after reset.
- Smart triggers can be globally paused.
- Profile apply still never silently runs bulk icon moves.
- Diagnostics exposes risky feature state.
```

---

## Task 5 — Real-system QA matrix

```text
Create a rigorous manual QA matrix for Alpha RC.

Create:
- docs/testing/alpha-rc-qa-matrix.md
- docs/testing/alpha-rc-qa-run-template.md
- docs/testing/known-risk-areas.md

The QA matrix must cover:

Basic Mode:
1. First launch.
2. Onboarding.
3. Command-drag separator placement.
4. Collapse/expand.
5. Reveal all.
6. Always-hidden section.
7. Option-click reveal all.
8. Auto-rehide.
9. Hover reveal.
10. Global hotkey.
11. Reset separator length.
12. Reset app layout.
13. Reset all settings.

macOS 26 visual states:
1. Transparent menu bar.
2. Tinted Liquid Glass setting if available.
3. Reduce Transparency.
4. Increase Contrast.
5. Light mode.
6. Dark mode.
7. Wallpaper variations.
8. Menu bar background visibility.

Display states:
1. Built-in display.
2. Notch display.
3. External display.
4. External display as primary.
5. External display disconnected while collapsed.
6. Display scaling changes.
7. Sleep/wake.
8. Full-screen app.
9. Space switch.

Pro Mode:
1. Pro Mode disabled.
2. Enable Pro Mode.
3. Request Accessibility permission.
4. Grant permission.
5. Revoke permission.
6. Relaunch after revoke.
7. Manual scan refresh.
8. Diagnostics table.
9. AX failure degradation.

Find Icon:
1. Unavailable state.
2. Search by app name.
3. Search by bundle id.
4. Keyboard navigation.
5. Activate visible item.
6. Activate hidden item.
7. Activate always-hidden item.
8. Highlight overlay.
9. Escape dismiss.
10. Hotkey.

Second Bar:
1. Unavailable state.
2. Below menu bar placement.
3. Near mouse placement.
4. Last position placement.
5. Search.
6. Keyboard navigation.
7. Auto-close.
8. Outside-click close.
9. External display.
10. Notch behavior.

Icon Moving:
1. Disabled by default.
2. First-use warning.
3. Move third-party app to Hidden.
4. Move third-party app to Visible.
5. Move third-party app to Always Hidden.
6. Move Left.
7. Move Right.
8. Reject own app items.
9. Reject system items by default.
10. Fail safely on unsupported items.
11. Permission revoke during move.
12. Display change during move.

Profiles/Triggers:
1. Create profile.
2. Duplicate profile.
3. Delete profile.
4. Export/import.
5. Dry run.
6. Apply Basic-only profile.
7. Confirm Pro moves are report-only.
8. Display trigger.
9. App launched trigger.
10. Time trigger.
11. Pause all automation.

Health/Safe Mode:
1. Force quit while collapsed.
2. Relaunch with crash marker.
3. Safe Mode via Option key.
4. Safe Mode next launch flag.
5. Fix Automatically.
6. Disable Pro Mode.
7. Export Health Report.

Release:
1. Archive.
2. Codesign verify.
3. Notarization template.
4. Install from exported artifact.
5. Launch at Login from installed app.
6. Uninstall cleanup notes.
```

Acceptance criteria:

```text
- QA matrix exists.
- QA run template allows PASS/FAIL/BLOCKED/NOT TESTED.
- Known-risk areas are explicitly documented.
- Current incomplete QA areas are not hidden.
```

---

## Task 6 — QA helper scripts

```text
Add helper scripts for repeatable alpha validation.

Create:
- scripts/qa_preflight.sh
- scripts/qa_collect_artifacts.sh
- scripts/qa_network_watch.sh
- scripts/verify_release_artifact.sh

qa_preflight.sh should:
1. Print macOS version.
2. Print architecture.
3. Print Xcode version.
4. Print current Git commit.
5. Run xcodebuild -list.
6. Run xcodebuild test with MenuBarDeclutter scheme.
7. Run privacy boundary verification.

qa_collect_artifacts.sh should collect:
1. Test logs.
2. Diagnostics exports if present.
3. Health reports if present.
4. App version/build info.
5. QA run template copy.
6. Do not collect screenshots automatically.
7. Do not collect screen contents.

qa_network_watch.sh should:
1. Accept app process name or PID.
2. Print a short manual command guide using lsof/nettop.
3. Not require network access.
4. Help user verify the app opens no unexpected network connections.

verify_release_artifact.sh should:
1. Check app bundle exists.
2. Check codesign status.
3. Check hardened runtime if applicable.
4. Check entitlements.
5. Check LSUIElement.
6. Check URL scheme.
7. Check no ScreenCaptureKit-linked framework usage if possible.
```

Acceptance criteria:

```text
- Scripts are executable.
- Scripts use set -euo pipefail.
- Scripts document what they can and cannot verify.
- Scripts do not upload anything.
```

---

## Task 7 — Improve diagnostics for real-world failures

```text
Add alpha-focused diagnostics events.

Add structured diagnostic event categories:
- startup
- shutdown
- statusItem
- separator
- hiding
- rehide
- hover
- hotkey
- accessibility
- scan
- search
- secondBar
- iconMove
- profile
- trigger
- health
- recovery
- safeMode
- launchAtLogin
- urlAutomation
- privacy

For each event, store:
- timestamp
- category
- severity
- message
- optional privacy-safe metadata

Add Diagnostics filters:
- show all
- warnings/errors only
- category filter
- copy selected event
- export filtered diagnostics

Do not log:
- screenshots
- screen contents
- live search text
- selected-item identity in export unless already redacted
- personal file paths outside app support
```

Acceptance criteria:

```text
- Diagnostics are useful during manual QA.
- Export remains privacy-safe.
- QA failures can be diagnosed without screen capture.
```

---

## Task 8 — Launch at Login real-install validation support

```text
Harden Launch at Login validation.

Implement:
1. Settings should display SMAppService status.
2. Diagnostics should display last registration/unregistration result.
3. Add “Open Login Items Settings” button if feasible.
4. Add docs explaining that Launch at Login must be tested from an installed signed app, not only from Xcode.
5. Add troubleshooting copy for stale login item registration.

Update:
- Core/LaunchAtLoginService.swift
- Settings/GeneralSettingsView.swift
- Settings/DiagnosticsSettingsView.swift
- docs/testing/alpha-rc-qa-matrix.md
- docs/testing/manual-qa.md
```

Acceptance criteria:

```text
- User can see Launch at Login status.
- User can recover from stale registration.
- QA docs distinguish Xcode run vs installed app behavior.
```

---

## Task 9 — Release candidate checklist

```text
Create an Alpha RC release checklist.

Create:
- docs/release/alpha-rc-checklist.md
- docs/release/alpha-rc-known-limitations.md
- docs/release/alpha-rc-release-notes-template.md

Checklist must require:
1. Clean working tree or documented diff.
2. xcodebuild test pass.
3. Privacy boundary verification pass.
4. Manual QA completed or documented as not tested.
5. Basic Mode pass.
6. Pro permission flow pass.
7. Icon moving either pass or marked experimental with known limitations.
8. External display test status.
9. Notch test status.
10. Launch at Login installed-app test status.
11. Safe Mode recovery test.
12. Codesign verification.
13. Notarization attempt or explicit skip reason.
14. Version/build number updated.
15. Known limitations included.

Known limitations should include:
- Phase 10 visual icon capture is intentionally not implemented.
- Second Bar uses app/bundle icons, not captured menu bar pixels.
- Icon moving is experimental.
- Some system menu bar items may not be movable or discoverable.
- AX metadata can be incomplete or stale.
- Profiles do not silently run mass icon moves.
- Trigger providers for Focus/Wi-Fi may remain inactive unless safe providers are added.
```

Acceptance criteria:

```text
- Release checklist is strict enough to block a weak alpha.
- Known limitations are user-facing and honest.
```

---

## Task 10 — Final validation commands

```text
At the end of Phase 9.1, run and report:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. scripts/verify_privacy_boundary.sh
5. scripts/qa_preflight.sh

If MenuBarDeclutter scheme cannot be created safely, run the same commands with MenuBar-Manager and document why the scheme rename was deferred.

Update:
- docs/status/phase-9.1-final-report.md

The final report should include:
- completed tasks
- skipped tasks with reasons
- test results
- privacy verification result
- remaining manual QA blockers
- recommendation for Alpha RC readiness
```

Acceptance criteria:

```text
- Final report exists.
- Build/test commands are recorded.
- Remaining risk is explicit.
```

---
