
# Phase 12 Codex Execution Pack

````markdown
# Codex Execution Pack
# Phase 12 — v0.1.1 Release Confidence & Trust Hardening

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar utility written in Swift, AppKit, and SwiftUI.

The product direction is privacy-first menu bar decluttering:
- Basic Mode is permission-free and uses public `NSStatusItem` behavior.
- Pro Mode is opt-in and uses Accessibility metadata only after explicit user enablement and explicit macOS permission grant.
- The app must not use Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network telemetry, cloud sync, or private Apple menu bar APIs.

This phase is **not v0.2**. Do not write `v0.2`, `0.2`, or `v0.2.0` anywhere except in historical docs if already present and explicitly marked historical. The target version line for this phase is:

`v0.1.1`

## Phase Mission

Phase 12 converts the current post-Phase-11 checkout into a release-confident `v0.1.1` candidate.

The goal is not to add more features. The goal is to harden release, trust, privacy, recovery, manual QA, feature claims, and installed-app behavior.

By the end of Phase 12:
- Basic Mode must be the stable product core.
- Pro and Labs features must be correctly gated and honestly described.
- Public claims must match actual working behavior.
- Release packaging must target `v0.1.1`.
- Manual QA gates must be documented and executable.
- Developer ID / notarization support must be implemented without requiring secrets in the repo.
- The app must remain privacy-first and no-network by default.

## Current Project Facts

Treat these as current constraints:

- Product name: `MenuBarDeclutter`
- Xcode project package: `MenuBar-Manager.xcodeproj`
- Canonical scheme: `MenuBarDeclutter`
- Compatibility scheme: `MenuBar-Manager`
- Fixture scheme: `MenuBarFixtureApp`
- Bundle ID: `Yongjun-Zhang.MenuBarDeclutter`
- Deployment target: macOS `26.0`
- Swift version: `6.0`
- App runtime: `LSUIElement`
- App Sandbox and hardened runtime are enabled.
- Local URL scheme: `menubardeclutter://`
- Existing validation previously passed:
  - `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
  - `scripts/qa_preflight.sh`
  - `scripts/verify_privacy_boundary.sh`
  - `scripts/qa_dogfood_preflight.sh`
  - `scripts/build_release.sh`
  - local alpha zip creation
  - installed-app verification after replacing stale `/Applications/MenuBarDeclutter.app`

## Hard Rules

1. Do not introduce ScreenCaptureKit.
2. Do not introduce Screen Recording permission.
3. Do not introduce Apple Events.
4. Do not introduce Input Monitoring.
5. Do not introduce network access, telemetry, analytics, crash upload, cloud sync, or remote config.
6. Do not use private Apple menu bar APIs.
7. Do not silently prompt for Accessibility.
8. Do not automatically mutate global menu bar spacing defaults.
9. Do not claim Icon Moving, Spacing Labs, Import/Export, App Intents, or Smart Triggers as stable unless the phase explicitly completes and tests that claim.
10. Do not rename the product or scheme.
11. Do not rename the repository folder unless unavoidable.
12. Do not call this phase or its release `v0.2`.

## Initial Repository Checks

Start by running:

```bash
git status --short
xcodebuild -list -project MenuBar-Manager.xcodeproj
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
````

If any command fails at baseline, inspect and fix only if the failure is clearly related to current source state. Document the baseline result in:

`docs/progress/phase-12-v0.1.1-release-confidence.md`

Create this progress file at the start of the phase.

---

# Workstream 12.1 — Version, Naming, and Release Identity

## Goal

Move the project’s active release target from `0.1.0` to `0.1.1`, without calling it v0.2.

## Tasks

1. Search for current version declarations:

   ```bash
   rg -n "0\.1\.0|v0\.1\.0|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
   ```

2. Update active app version to:

   * marketing version: `0.1.1`
   * build number: increment from current `1` to `2`, unless the project already uses a different build strategy.

3. Make sure release artifact names use:

   * `MenuBarDeclutter-v0.1.1.zip`
   * `MenuBarDeclutter-v0.1.1-alpha.zip` only if alpha/dogfood packaging still exists.

4. Add a guard in release scripts or docs that this phase is not `v0.2`.

5. Update docs that represent current release state:

   * `README.md`
   * `docs/roadmap/post-v0.1.md`
   * latest `docs/release/` docs
   * latest `docs/progress/` status doc
   * app-facing release text if present

6. Do not rewrite historical phase logs unless they create current-state confusion.

## Acceptance Criteria

* `rg -n "v0\.2|0\.2\.0" docs MenuBar-Manager scripts Config` returns no current-release references.
* App bundle reports `0.1.1`.
* Release zip names use `v0.1.1`.
* Historical notes, if any, are clearly historical and not roadmap/current release names.

---

# Workstream 12.2 — Developer ID Export and Notarization Support

## Goal

Make release tooling ready for real Developer ID distribution while still supporting dry-run local packaging when credentials are absent.

## Tasks

1. Add `Config/ExportOptions.plist` if missing.

   Requirements:

   * outside Mac App Store distribution
   * Developer ID method
   * hardened runtime compatible
   * no secrets
   * no team ID hardcoded unless the existing project already has a safe convention

2. Update `scripts/build_release.sh`.

   It should support:

   * `--dry-run`
   * `--notarize`
   * `--staple`
   * `--install`
   * `--verify-installed`
   * `--version 0.1.1` or derive version from project config
   * helpful failure messages when Developer ID credentials are missing

3. Add or update release verification script.

   It should check:

   * app bundle exists
   * bundle ID
   * version/build
   * LSUIElement
   * sandbox entitlement
   * hardened runtime
   * local URL scheme
   * no unexpected network entitlement
   * no ScreenCaptureKit linkage
   * no NSAppleEventsUsageDescription
   * no NSScreenCaptureUsageDescription unless intentionally absent
   * code signature validity
   * spctl assessment when notarized or installed
   * stapler validation when stapled

4. Add notarytool support.

   Use environment variables or keychain profile only. Do not commit credentials.

   Acceptable inputs:

   * `NOTARYTOOL_KEYCHAIN_PROFILE`
   * or Apple ID / team / app-specific password env vars if already used by repo convention

5. Fix the documented App Category archive warning.

   Search current plist/build settings. Add or correct `LSApplicationCategoryType`, likely utility category, using the repo’s existing Info.plist/build settings style.

6. Update release docs:

   * `docs/release/v0.1.1-release-runbook.md`
   * `docs/release/notarization-setup.md`
   * `docs/release/v0.1.1-release-checklist.md`
   * `docs/release/v0.1.1-local-dry-run.md`

## Acceptance Criteria

* Dry-run build still works without Developer ID credentials.
* Real notarization path exists and fails clearly when credentials are absent.
* Release artifact verification passes for dry-run artifacts except expected notarization/stapling warnings.
* App Category archive warning is resolved or explicitly documented with proof if impossible.
* No secrets are committed.

---

# Workstream 12.3 — Basic Mode Reliability Freeze

## Goal

Basic Mode is the v0.1.1 stable core. It must remain reliable even when Pro, Automation, Labs, Private Access, Hotkeys, or import/export are unavailable or broken.

## Tasks

1. Audit Basic Mode state transitions:

   * collapsed
   * expanded
   * reveal all
   * always-hidden reveal
   * Option-click reveal all
   * auto-rehide pending
   * hover reveal active
   * Safe Mode expanded state
   * display change geometry recompute
   * wake recovery
   * reset app layout

2. Fix the `showPrimarySeparator` mismatch.

   Current known limitation:

   * `showPrimarySeparator` is persisted/exported.
   * `StatusBarController` currently always installs the primary separator.

   Preferred v0.1.1 fix:

   * Treat the primary separator as required for Basic Mode.
   * Remove user-facing claims that it can be hidden.
   * Deprecate or sanitize the persisted setting to true.
   * Exclude it from real settings export if it creates false configurability.
   * Add migration/repair logic if needed.
   * Add diagnostics note only if useful.

   Do not remove the primary separator in a way that weakens recovery.

3. Verify startup order:

   * install status items
   * health check
   * recovery if needed
   * only then apply start-collapsed preference

4. Confirm Safe Mode:

   * always starts expanded
   * suppresses optional services
   * preserves visible Basic control
   * keeps reset/recovery status menu access

5. Add tests for:

   * corrupted separator lengths
   * invalid screen geometry
   * start-collapsed after recovery
   * Safe Mode suppressing risky services
   * Reset App Layout not needing Pro
   * persisted state migration around `showPrimarySeparator`

6. Add or update:

   * `docs/features/basic-mode-v0.1.1-contract.md`

## Acceptance Criteria

* Basic Mode works with Pro off.
* Basic Mode works with Accessibility denied/revoked.
* Basic Mode works in Safe Mode.
* Reset/recovery path does not require Pro, Accessibility, Screen Recording, or network.
* `showPrimarySeparator` no longer appears as a misleading user-facing option.

---

# Workstream 12.4 — Feature Claim Audit and Gate Cleanup

## Goal

Every feature shown in UI/docs must be classified honestly as Stable, Preview, Labs, Experimental, Unavailable, or Deferred.

## Tasks

1. Create a central feature status model if one does not exist.

   Suggested statuses:

   * Stable
   * Preview
   * Labs
   * Experimental
   * Disabled
   * Unavailable
   * Deferred

2. Add reusable UI badges under `DesignSystem/`, for example:

   * `FeatureStatusBadge`
   * `FeatureGateNotice`
   * `FeatureAvailabilityRow`

3. Audit all Settings sections:

   * General
   * Behavior
   * Layout
   * Search
   * Second Bar
   * Private Access
   * Groups
   * Hotkeys
   * Profiles
   * Automation
   * Import / Export
   * Privacy
   * Diagnostics
   * Advanced

4. Stable in v0.1.1:

   * Basic expand/collapse/reveal-all
   * auto-rehide
   * hover reveal
   * always-hidden zone
   * global visibility hotkey
   * Launch at Login
   * diagnostics export
   * Safe Mode / Recovery
   * Pro Accessibility Discovery gating
   * Find Icon search + reveal/highlight only
   * Second Bar metadata/icon browsing
   * local profiles basic dry-run/apply for conservative settings
   * local privacy boundary

5. Preview / Labs / Experimental in v0.1.1:

   * Icon Moving: Experimental
   * Smart Triggers: Preview, off and paused by default
   * Dynamic Hotkeys: Preview unless fully hardened
   * Private Access: Preview unless Workstream 13 later completes it
   * Group status items: Preview or Experimental, off by default
   * Menu Bar Spacing Labs: Labs
   * App Intents automation: Preview
   * Import/Export migration assistant: Preview/Dry-run unless completed later
   * Crowded Reveal Rescue automation: Preview until wired into real reveal path

6. Hide or downgrade:

   * settings export placeholder values
   * import commit/apply if not implemented
   * spacing preset intent that only logs/validates
   * Focus/Wi-Fi trigger providers if inactive
   * broad “activate any menu bar item” claims
   * broad “import from Bartender/Ice” claims
   * any claim that Private Access hides third-party icons already visible in the system menu bar

7. Update:

   * `docs/release/v0.1.1-public-claims.md`
   * `docs/release/v0.1.1-feature-gates.md`
   * `docs/privacy/v0.1.1-privacy-claims.md`

## Acceptance Criteria

* No current UI copy overclaims scaffolded features.
* All risky features are off by default.
* Labs features are clearly marked Labs.
* Experimental features require explicit enablement or confirmation.
* Release notes match actual gates.
* Tests cover unavailable/degraded states for at least Search, Second Bar, App Intents, Import/Export, Spacing Labs, Icon Moving, and Private Access.

---

# Workstream 12.5 — Privacy & Trust Pack

## Goal

Make the privacy boundary obvious in the product, docs, diagnostics, and release validation.

## Tasks

1. Add or polish Settings → Privacy.

   It must explicitly state:

   * Basic Mode does not request Accessibility.
   * Basic Mode does not request Screen Recording.
   * The app does not use ScreenCaptureKit.
   * The app does not request Apple Events.
   * The app does not request Input Monitoring.
   * The app does not use network telemetry, analytics, crash upload, cloud sync, or remote config.
   * Diagnostics exports exclude screenshots, screen contents, live search text, selected item identity, protected group names, protected hotkey targets, active unlock sessions, and import/export paths unless explicitly chosen by the user.

2. Add Pro Mode permission explainer.

   It must distinguish:

   * Pro Mode feature toggle
   * Accessibility Discovery toggle
   * macOS Accessibility permission
   * explicit permission request button

3. Confirm no automatic Accessibility prompt.

4. Add diagnostics export preview if feasible.

   The user should be able to inspect what will be exported before saving.

5. Update privacy verification script.

   It should detect accidental additions of:

   * ScreenCaptureKit import/linkage
   * screen capture usage description
   * Apple Events usage description
   * network entitlements
   * suspicious URLSession/network usage in app target
   * telemetry/analytics SDK names if obvious

6. Add/update tests:

   * diagnostics redaction
   * dogfood export redaction
   * protected resource redaction
   * no live search query in diagnostics
   * no selected item identity in diagnostics

## Acceptance Criteria

* `scripts/verify_privacy_boundary.sh` passes.
* No Pro/AX prompt appears unless the user explicitly asks for permission request.
* Privacy page explains Basic vs Pro clearly.
* No ScreenCaptureKit appears in app target.
* No network access is introduced.
* Diagnostics export remains privacy-safe.

---

# Workstream 12.6 — Native Cleanup Onboarding

## Goal

Teach users that Apple’s native Menu Bar / Control Center settings and MenuBarDeclutter are complementary.

This increases trust and reduces crowded-menu-bar problems before the app’s own hiding system starts.

## Tasks

1. Add an onboarding step:

   * title: “Start with Apple’s Menu Bar settings”
   * explain that users can move rarely-used system controls into Control Center before using MenuBarDeclutter.
   * explain that MenuBarDeclutter helps with third-party and crowded menu bar workflows.
   * do not claim to replace Apple’s settings.

2. Add a best-effort button:

   * “Open Menu Bar Settings”
   * Try a safe System Settings deep link if one already exists in the repo.
   * Fall back to opening System Settings.
   * Do not require permissions.
   * Do not automate system setting changes.

3. Add docs:

   * `docs/onboarding/native-cleanup.md`

4. Add UI tests or smoke tests:

   * onboarding renders
   * button action does not crash
   * onboarding completion is persisted in isolated test defaults

## Acceptance Criteria

* First-run onboarding includes native cleanup step.
* No extra permission is triggered.
* User understands that Apple native cleanup happens before app-specific hidden zones.
* The feature works in UI-test isolation.

---

# Workstream 12.7 — App Intents and URL Automation Fail-Closed Gate

## Goal

Even if full automation completion is deferred to Phase 13, Phase 12 must ensure App Intents and URL automation do not bypass global pause, Safe Mode, Pro gates, Private Access gates, or Labs gates.

## Tasks

1. Locate current URL automation and App Intents execution paths:

   * `Profiles/`
   * `Shortcuts/`
   * `App/`
   * `Settings/Automation`
   * any URL router handling `menubardeclutter://`

2. Add or consolidate a minimal `AutomationCommandGate`.

   It should check:

   * Safe Mode
   * automation globally enabled if such a setting exists
   * automation paused
   * Pro Mode required
   * Accessibility required
   * Labs required
   * Private Access required
   * feature disabled
   * dry-run only

3. Make existing App Intents and URL commands use this gate.

4. For Phase 12, it is acceptable for some commands to return:

   * unavailable
   * dry-run only
   * blocked by Labs gate
   * blocked by Pro gate

5. Update docs so automation is described as Preview unless Phase 13 completes it.

6. Add tests:

   * Safe Mode blocks automation
   * automation pause blocks triggers and URL commands
   * Pro-required actions fail closed when Pro is off
   * Labs actions fail closed when Labs is off
   * Private Access protected action does not execute unlocked unless gate allows

## Acceptance Criteria

* No automation path bypasses Safe Mode.
* No URL route applies Labs settings when Labs is off.
* No App Intent executes a protected action without gate result.
* Automation docs and UI are honest.

---

# Workstream 12.8 — Import/Export Safety Patch

## Goal

Prevent misleading migration behavior in v0.1.1.

Current known issue:

* Settings export writes placeholder setting values.
* Import is dry-run only with backup creation.

Phase 12 should either hide incomplete apply paths or clearly mark them Preview/Dry-run.

## Tasks

1. Audit:

   * `Migration/`
   * `Settings/ImportExport`
   * profile import/export
   * group import/export
   * dogfood export
   * diagnostics export

2. For current v0.1.1:

   * Diagnostics export remains stable.
   * Dogfood export remains stable.
   * Profile/group export can remain if real.
   * Full settings export must not write fake values.
   * Import apply/commit must not appear available unless implemented.

3. Replace placeholder values with one of:

   * real current values, or
   * explicitly omitted fields, or
   * a dry-run sample clearly not labeled as export.

4. Add schema metadata:

   * app version
   * export schema version
   * export kind
   * created date
   * redaction mode

5. Add tests:

   * no placeholder values in real export
   * dry-run import does not mutate settings
   * backup creation path works
   * protected names/targets are redacted by default

## Acceptance Criteria

* User cannot accidentally trust a fake settings export.
* Import apply is hidden or disabled unless real.
* Exports are schema-versioned.
* Privacy-safe export remains safe.

---

# Workstream 12.9 — Manual QA Matrix and Dogfood Evidence

## Goal

Turn manual system gates into a concrete release matrix.

## Tasks

Create:

* `docs/testing/manual-v0.1.1-system-qa.md`
* `docs/testing/manual-v0.1.1-results-template.md`
* `docs/testing/manual-v0.1.1-known-acceptable-risks.md`
* `docs/testing/manual-v0.1.1-dogfood-script.md`

The QA matrix must include:

1. Basic live menu bar:

   * command-drag control/separators
   * collapse
   * expand
   * reveal all
   * reset layout

2. Crowded menu bar:

   * many third-party status items
   * expanded mode
   * hidden items pushed offscreen
   * Second Bar fallback availability

3. Notch layouts:

   * notch MacBook
   * hidden item search
   * Second Bar placement
   * layout suggestions

4. External displays:

   * attach display
   * detach display
   * switch main display
   * mirror mode
   * different menu bar heights

5. Sleep/wake and Space changes.

6. Menu bar appearance variants:

   * light mode
   * dark mode
   * auto-hide menu bar
   * menu bar background on/off

7. Launch at Login:

   * installed `/Applications` app
   * logout/login
   * restart
   * removal

8. Pro permission:

   * Accessibility grant
   * revoke
   * restart
   * Pro off/on
   * discovery off/on

9. Safe Mode:

   * Option launch
   * one-shot flag
   * crash marker recovery

10. Private Access:

    * Touch ID success
    * cancel
    * unavailable
    * failure
    * session expiration

11. Shortcuts / App Intents:

    * discover actions
    * run stable actions
    * blocked states

12. Labs:

    * Spacing Labs dry-run only unless full apply/restore is implemented later
    * no automatic system process restart

13. Experimental:

    * Icon Moving manual-only
    * no stable public claim

## Acceptance Criteria

* Manual QA docs exist and are specific enough for a tester.
* Each gate has expected result and failure capture guidance.
* Dogfood export remains privacy-safe.
* Release checklist links to manual QA docs.

---

# Workstream 12.10 — Documentation and Release Notes

## Goal

Make v0.1.1 understandable to a new user and honest to a power user.

## Tasks

Update or create:

* `README.md`
* `docs/release/v0.1.1-release-notes.md`
* `docs/release/v0.1.1-known-limitations.md`
* `docs/support/troubleshooting.md`
* `docs/support/uninstall.md`
* `docs/support/permissions.md`
* `docs/support/safe-mode.md`
* `docs/privacy/v0.1.1-privacy-claims.md`
* `docs/features/basic-mode-v0.1.1-contract.md`
* `docs/features/pro-mode-v0.1.1-boundary.md`
* `docs/progress/phase-12-v0.1.1-release-confidence.md`

Docs must explain:

* What Basic Mode does.
* What Pro Mode does.
* What Pro Mode does not do.
* What Labs means.
* Why Accessibility is optional.
* Why Screen Recording is not used.
* Why ScreenCaptureKit is deferred.
* How to reset layout.
* How to enter Safe Mode.
* How to fully uninstall.
* How to export diagnostics.
* How to report a bug without screenshots.
* Which features are Stable, Preview, Labs, Experimental, or Deferred.

## Acceptance Criteria

* Docs use `v0.1.1`, not `v0.2`.
* Docs match UI gates.
* Docs do not overclaim.
* User can install, use, recover, export diagnostics, and uninstall using docs only.

---

# Required Tests and Commands

After implementation, run:

```bash
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Also run targeted searches:

```bash
rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true
rg -n "placeholder|TODO|FIXME|stub|scaffold" MenuBar-Manager/Migration MenuBar-Manager/Shortcuts MenuBar-Manager/Layout docs/release docs/features || true
```

For the last search, do not blindly remove every TODO. Inspect each result. Fix current-release misleading items and document deferred items.

---

# Phase 12 Definition of Done

Phase 12 is complete when:

1. App version and release artifacts target `v0.1.1`.
2. No current-facing docs or UI call the next release `v0.2`.
3. Release tooling supports Developer ID/notarization without committing secrets.
4. Dry-run release still passes.
5. Installed-app verification still passes locally.
6. Basic Mode has a documented v0.1.1 contract.
7. Safe Mode and recovery remain permission-free.
8. Feature gates are honest and fail closed.
9. App Intents and URL automation cannot bypass Safe Mode or automation pause.
10. Import/export no longer presents fake settings as real.
11. Privacy boundary is documented and script-verified.
12. Native cleanup onboarding exists.
13. Manual QA matrix exists.
14. All required tests pass.
15. `docs/progress/phase-12-v0.1.1-release-confidence.md` contains:

    * summary
    * changed files
    * test results
    * known limitations
    * deferred work for Phase 13

````

---

# 建议的执行顺序

## Phase 12 分批

1. **12A — Version / Release / Notarization**
   - version `0.1.1`
   - release scripts
   - ExportOptions
   - App Category warning
   - release docs

2. **12B — Basic Reliability / Feature Claims**
   - Basic contract
   - `showPrimarySeparator` 修正
   - Feature status badges
   - UI claim audit

3. **12C — Privacy / Onboarding / Automation Fail-Closed**
   - Privacy page
   - Native cleanup onboarding
   - App Intents / URL fail-closed gate
   - Import/export placeholder cleanup

4. **12D — Manual QA / Docs / Final Validation**
   - manual QA matrix
   - support docs
   - v0.1.1 release notes
   - full test suite

---
