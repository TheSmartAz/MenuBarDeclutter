Implement Phase 0 — macOS 26+ Project Bootstrap + Reference Audit.

Context:
We are building MenuBarDeclutter, a native macOS 26+ menu bar decluttering app using Swift, AppKit, and SwiftUI.

Phase goal:
Create the project skeleton, app lifecycle, menu bar app baseline, documentation, and license/research boundaries. Do not implement real hiding yet.

Tasks:

1. Inspect repository.
   - Run:
     - ls
     - find . -maxdepth 3 -type f
     - xcodebuild -list
   - If no Xcode project exists, document that the user should create a macOS App project in Xcode 26.x named MenuBarDeclutter.
   - If project exists, adapt without deleting existing files.

2. Configure macOS 26+ target.
   - Set minimum deployment target to macOS 26.0.
   - Prefer Swift 6 mode if available.
   - Enable hardened runtime for release configuration if possible.
   - Keep App Sandbox decision documented but do not force sandbox yet.
   - Add LSUIElement = YES so the app appears as a menu bar utility without Dock icon.

3. App lifecycle.
   Create:
   - App/MenuBarDeclutterApp.swift
   - App/AppDelegate.swift
   - App/AppConstants.swift
   - App/AppEnvironment.swift

   Requirements:
   - Use SwiftUI app lifecycle.
   - Use @NSApplicationDelegateAdaptor(AppDelegate.self).
   - AppDelegate owns the AppEnvironment.
   - AppEnvironment owns major services.
   - Set app activation policy appropriately for menu bar utility behavior.

4. Temporary status item.
   Create:
   - StatusBar/StatusBarController.swift
   - StatusBar/StatusBarMenuBuilder.swift

   Behavior:
   - Show one temporary NSStatusItem.
   - Left click opens a simple menu or toggles a placeholder state.
   - Menu includes:
     - Settings
     - Show Diagnostics
     - About
     - Quit

5. Settings skeleton.
   Create:
   - Settings/SettingsWindowController.swift
   - Settings/SettingsRootView.swift
   - Settings/GeneralSettingsView.swift
   - Settings/PrivacySettingsView.swift
   - Settings/DiagnosticsSettingsView.swift

   The settings window should open from the status item menu.

6. Core infrastructure.
   Create:
   - Core/SettingsStore.swift
   - Core/DiagnosticsLogger.swift
   - Core/AppSupportPaths.swift

   SettingsStore:
   - Use UserDefaults.
   - Provide typed keys.
   - Initial settings:
     - hasCompletedOnboarding: Bool
     - launchAtLoginEnabled: Bool
     - lastKnownAppVersion: String
     - appMode: "basic"

   DiagnosticsLogger:
   - Console logging in DEBUG.
   - In-memory ring buffer of last 200 events.
   - No files yet unless needed.

7. Documentation.
   Create:
   - AGENTS.md
   - docs/PLAN.md
   - docs/architecture/architecture-overview.md
   - docs/research/github-reference.md
   - docs/research/license-matrix.md
   - docs/research/macos26-notes.md
   - docs/testing/manual-qa.md
   - docs/testing/macos26-test-matrix.md
   - docs/release-checklist.md

8. Reference/license documentation.
   In docs/research/license-matrix.md, document:
   - Hidden Bar: can study; check actual license before any code reuse.
   - Dozer: can study; check actual license before any code reuse.
   - Ice/Thaw: GPL-style risk; do not copy code unless project accepts GPL.
   - SaneBar: source-available / competitive-use restriction risk; do not copy code.
   - Our implementation must be original.

9. macOS 26-specific notes.
   In docs/research/macos26-notes.md, document:
   - Target macOS 26.0+ only.
   - Test transparent menu bar and menu bar background enabled/disabled.
   - Test Liquid Glass / Reduce Transparency / Increase Contrast.
   - Test Control Center/menu bar controls because macOS 26 adds more menu bar customization.
   - Test notch displays.
   - Test external displays.
   - Test Apple Silicon primary.
   - Intel support decision should be documented separately.

10. Scripts.
   Create:
   - scripts/build_debug.sh
   - scripts/build_release.sh
   - scripts/test.sh

   Scripts should:
   - set -euo pipefail
   - print exact xcodebuild command
   - use scheme MenuBarDeclutter
   - use destination platform=macOS

11. Tests.
   Create MenuBarDeclutterTests if not present.
   Add simple tests:
   - SettingsStore default values.
   - DiagnosticsLogger ring buffer retains latest events.

Acceptance criteria:
- App builds on macOS 26+ target.
- App launches as a menu bar utility.
- No Dock icon if LSUIElement is applied.
- Temporary status item appears.
- Settings opens.
- Quit works.
- docs/ and scripts/ exist.
- No Accessibility or Screen Recording permission prompt appears.
- No third-party dependency is introduced.

Out of scope:
- No real hiding.
- No hotkey.
- No auto-hide.
- No Accessibility.
- No search.
- No second bar.