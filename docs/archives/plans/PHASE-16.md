
---

# v0.1.3 Codex Execution Pack

```markdown
# Codex Execution Pack
# Phase 16 — v0.1.3 Competitive Core Catch-up

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows v0.1.2. v0.1.2 should have made the product feel lighter through Settings diet, Guided Arrange polish, Find & Rescue polish, status menu simplification, Pro setup explanation, and manual QA evidence.

This phase is `v0.1.3`, not v0.2.

Do not create a v0.2 execution pack. Do not use `v0.2`, `0.2`, or `v0.2.0` in current-facing docs, UI, release notes, artifact names, package names, roadmap copy, or code comments.

## Version Target

Set the active app version to:

- Marketing version: `0.1.3`
- Build number: increment from `3` to `4`, unless the project has already advanced its build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.3.zip`
- `MenuBarDeclutter-v0.1.3-alpha.zip` only if alpha/dogfood packaging still exists.

## Phase Mission

v0.1.3 is the competitive core catch-up release.

The goal is to make the core experience competitive with lightweight and power-user menu bar managers without becoming heavy again.

The focus is:

1. Find & Rescue speed and daily usability.
2. Second Bar reliability and item actions.
3. Crowded/notch/external-display behavior.
4. Guided Arrange and Placement Planner quality.
5. Assisted Move guardrails and dogfood evidence.
6. Local backup/restore confidence.
7. Shortcuts/App Intents basic validation.
8. Real release pipeline rehearsal where credentials are available.

Do not add broad new product pillars.

## Hard Rules

1. Do not call this v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, or update checks.
7. Do not use private Apple menu bar APIs.
8. Do not silently prompt for Accessibility.
9. Do not make fully automated icon moving stable.
10. Do not add bulk icon moving.
11. Do not make broad third-party menu item activation stable.
12. Do not turn Smart Triggers into a main product pillar.
13. Do not turn Spacing Labs into a normal product surface.
14. Do not add competitor import as a stable claim.
15. Do not add a theme engine.
16. Keep Basic Mode stable and permission-free.
17. Keep Pro Discovery opt-in.
18. Keep Assisted Move Experimental.
19. Keep advanced automation nested.

## Initial Repository Checks

Run before making changes:

```bash
git status --short
xcodebuild -list -project MenuBar-Manager.xcodeproj
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
````

Create the progress file:

`docs/progress/phase-16-v0.1.3-competitive-core-catch-up.md`

Record:

* baseline git status
* baseline tests
* baseline release dry-run
* baseline installed app verification
* known manual QA blockers
* exact date
* short phase goal

---

# Workstream 16.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.2` to `0.1.3`.

## Tasks

1. Search for version references:

```bash
rg -n "0\.1\.2|v0\.1\.2|0\.1\.3|v0\.1\.3|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.3`
* build `4`

3. Update release artifact naming.

4. Add release notes:

`docs/release/v0.1.3-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.3-release-checklist.md`

6. Keep v0.2 out of current-facing docs.

## Acceptance Criteria

* App bundle reports `0.1.3`.
* Release artifacts use `v0.1.3`.
* Current-facing docs/UI do not refer to v0.2.
* Historical references remain clearly historical only.

---

# Workstream 16.2 — Find & Rescue Performance and Usability

## Goal

Make Find & Rescue feel fast, predictable, and useful as a daily tool.

## Key User Actions

A user should be able to:

* open Find Icon quickly
* search by app name/title
* navigate by keyboard
* reveal item
* highlight item
* show item in Second Bar
* open owning app
* arrange item manually
* run Assisted Move dry-run
* review new items
* recover if metadata is stale

## Tasks

1. Inspect:

* `MenuBar-Manager/Search/`
* `MenuBar-Manager/SecondBar/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/Accessibility/`
* `MenuBar-Manager/Core/menu-bar-item-memory.json` related code
* diagnostics around search and item memory

2. Add lightweight performance instrumentation.

Track privacy-safe timing only:

* search index rebuild time
* query ranking time
* panel open time
* latest scan age
* result count
* no query text
* no raw item identity
* no protected names

3. Set practical targets.

Suggested targets for test/fixture data:

* panel open should feel instant
* ranking should be under a small threshold for fixture-sized item sets
* no repeated full index rebuild on every keystroke if avoidable

4. Improve ranking quality:

* app name exact/prefix match
* title exact/prefix match
* bundle ID contains match
* recent/favorite boost
* new item boost
* hidden/always-hidden priority when searching from Find & Rescue
* stale item penalty

5. Improve keyboard actions:

* Enter: default action
* Command+Enter: show in Second Bar
* Option+Enter: open owning app
* Shift+Enter: reveal all relevant zone, if useful
* Escape: close
* Command+K or configured hotkey: open Find Icon, if already supported

6. Improve empty states:

* “No matching items”
* “Pro Discovery is off”
* “Accessibility permission is missing”
* “No scan yet”
* “Scan may be stale”
* “Safe Mode is active”

7. Add tests:

* ranking behavior
* recents/favorites boost
* new item boost
* stale penalty
* keyboard command routing
* search timing diagnostics redaction
* no live query export

## Acceptance Criteria

* Find Icon feels like a daily-use feature.
* Search ranking is better and tested.
* Keyboard navigation is documented and tested.
* Performance diagnostics are privacy-safe.
* No query text or item identity leaks into diagnostics export.

---

# Workstream 16.3 — Second Bar Reliability and Item Actions

## Goal

Make Second Bar useful enough to compete with separate-bar / icon-panel workflows.

Second Bar is still metadata/app-icon based. It does not capture pixels and should not claim to duplicate the live menu bar.

## Required Actions

Each eligible item should support:

* reveal
* highlight
* show in Find Icon
* open owning app
* arrange manually
* add to collection/group
* dry-run assisted move
* try assisted move, Experimental and gated
* experimental activation, only if already implemented and still gated

## Tasks

1. Inspect:

* `MenuBar-Manager/SecondBar/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/Groups/`
* `MenuBar-Manager/Search/`

2. Improve placement reliability:

* below menu bar
* near mouse
* last position
* current display
* external display changes
* sleep/wake reposition
* active Space changes
* menu bar height changes
* notch-aware clamping

3. Add or polish item action menu.

Use shared Command Center routing.

4. Add panel modes if already present:

* compact
* detailed
* labels on/off
* zone badges
* collection filter
* new item filter

Do not build a full visual live menu bar clone.

5. Add failure and unavailable states:

* Pro off
* Discovery off
* Accessibility missing
* stale scan
* no hidden items
* Safe Mode

6. Add tests:

* placement calculations
* display change handling
* item action availability
* command routing
* protected item redaction
* no screenshot/pixel dependency
* stale scan handling

## Acceptance Criteria

* Second Bar opens reliably.
* Second Bar item actions are useful.
* Placement is robust in simulated display scenarios.
* Real display scenarios are documented in manual QA.
* No ScreenCaptureKit or Screen Recording is introduced.

---

# Workstream 16.4 — Crowded and Notch Rescue Hardening

## Goal

Make crowded-menu behavior real and evidence-backed.

The user problem:

> I clicked reveal, but the menu bar is too crowded or the notch/app menus hide my icons.

The app should choose a clear fallback:

1. inline reveal if likely enough room
2. Second Bar if crowded
3. Full Menu Bar Mode if user prefers it or Second Bar unavailable
4. ask user if configured
5. recovery/suggestion if blocked

## Tasks

1. Inspect:

* `MenuBar-Manager/Layout/`
* `MenuBar-Manager/Hiding/`
* `MenuBar-Manager/SecondBar/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Settings/FindAndRescue`
* `MenuBar-Manager/Settings/Arrange`

2. Harden `CrowdedRevealDecisionEngine`.

Inputs should include:

* estimated capacity
* hidden count
* always-hidden count
* notch risk
* display width
* active display
* active app menu pressure if estimable
* Pro availability
* Second Bar availability
* Full Menu Bar Mode setting
* Safe Mode
* user preference

3. Ensure decision engine is used by:

* status menu reveal
* Basic expand
* reveal all
* Find Icon reveal
* group/collection reveal
* New Item action reveal

4. Add explanation UI:

* “Opened Second Bar because inline reveal may not fit.”
* “Full Menu Bar Mode temporarily reveals items.”
* “Try Apple’s Menu Bar settings to reduce system items.”
* “Use Arrange to move items manually.”

5. Add tests:

* inline enough room
* crowded -> Second Bar
* crowded + Second Bar unavailable -> Full Menu Bar Mode
* ask preference
* Safe Mode blocks automation
* Pro off uses Basic fallback
* diagnostics redaction

6. Update manual QA:

`docs/testing/manual-v0.1.3-crowded-notch-qa.md`

Include:

* notch MacBook
* external monitor
* long app menus
* many third-party menu bar apps
* menu bar auto-hide
* light/dark mode
* sleep/wake
* active Space changes

## Acceptance Criteria

* Crowded reveal behavior is predictable.
* User gets a clear explanation.
* Second Bar fallback is reliable.
* Manual QA matrix exists for notch/crowded scenarios.
* No private APIs or screen capture are introduced.

---

# Workstream 16.5 — Guided Arrange and Placement Planner Quality

## Goal

Make arranging icons one of the app’s strongest advantages.

v0.1.2 should have made Arrange usable. v0.1.3 should make it polished and practical.

## Tasks

1. Inspect:

* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/Accessibility/`
* `MenuBar-Manager/Search/`
* `MenuBar-Manager/SecondBar/`
* `MenuBar-Manager/CommandCenter/`

2. Improve Guided Manual Arrange:

* better diagrams
* clearer control/separator explanation
* short “why this works” explanation
* “common mistakes” section
* “test your layout” checklist
* “reset if wrong” path

3. Improve Placement Planner:

* clear recommendation reasons
* user can mark item preference:

  * keep visible
  * hide
  * always hide
  * review later
* no mutation by default
* manual instruction per recommendation
* handoff to Assisted Move dry-run

4. Add item preference persistence.

Use privacy-safe storage where possible.

Do not export raw sensitive identities by default.

5. Add tests:

* recommendation reason generation
* item preference persistence
* manual instruction generation
* no mutation from planner
* Pro gates
* privacy-safe diagnostics

## Acceptance Criteria

* Arrange flow feels beginner-friendly.
* Placement Planner gives useful guidance.
* Planner does not mutate layout.
* User preferences influence future recommendations.
* Tests pass.

---

# Workstream 16.6 — Assisted Move Dogfood and Guardrail Hardening

## Goal

Keep Assisted Move available but Experimental, while collecting enough evidence to know if it can ever become Preview later.

Assisted Move should not be a v0.1.3 stable claim.

## Tasks

1. Inspect:

* `MenuBar-Manager/Moving/`
* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Health/`
* moving tests

2. Harden required gates:

* Pro Mode
* Accessibility Discovery
* Accessibility permission
* Icon Moving enabled
* Experimental setting enabled
* first-use confirmation
* per-move confirmation
* valid item frame
* target zone selected
* Safe Mode inactive
* own status item blocked
* likely system item blocked by default
* no bulk moving

3. Improve dry-run:

* show source item
* show current zone
* show target zone
* show planned drag direction
* show risk reason
* no CGEvent

4. Improve result flow:

* success with verified target zone
* failed verification
* cancelled
* blocked
* timed out
* metadata stale
* user recovery actions

5. Add dogfood log.

Privacy-safe fields only:

* move attempted
* source zone kind
* target zone kind
* result kind
* failure reason kind
* duration bucket
* no raw item name
* no bundle ID unless user explicitly exports debug data
* no screenshots

6. Add manual QA doc:

`docs/testing/manual-v0.1.3-assisted-move-dogfood.md`

7. Add tests:

* all gates
* dry-run no CGEvent
* own item blocked
* system item blocked
* failure restores visibility state
* dogfood log redaction
* Safe Mode blocked

## Acceptance Criteria

* Assisted Move is safer and better documented.
* It remains Experimental.
* Dogfood evidence can be collected without privacy leakage.
* Failures offer recovery.
* No bulk move exists.

---

# Workstream 16.7 — New Item Inbox Dogfood and Polish

## Goal

Make New Item Inbox a real differentiator.

The user problem:

> A new app added a menu bar item. Where did it go, and should it be visible or hidden?

## Tasks

1. Inspect:

* `MenuBar-Manager/Arrange/NewMenuBarItem*`
* `MenuBar-Manager/Search/`
* `MenuBar-Manager/SecondBar/`
* item memory store
* fixture app scripts

2. Improve detection:

* compare latest discovered item hashes against known items
* avoid duplicate alerts
* handle renamed/stale items
* support dismissed items
* support reset inbox

3. Review actions:

* keep visible
* hide manually
* always hide manually
* add to collection
* show in Find Icon
* show in Second Bar
* arrange manually
* assisted move dry-run, Experimental

4. Add fixture support if needed:

* deterministic new item scenario
* repeated launch
* renamed item scenario if feasible

5. Add tests:

* new item detected once
* dismissed item not repeated
* reset inbox
* stale item not wrongly detected as new if identity stable
* review action routing
* diagnostics redaction

6. Add docs:

`docs/features/new-item-inbox-v0.1.3.md`

## Acceptance Criteria

* New Item Inbox works with fixture app.
* It is useful and not noisy.
* It integrates with Find & Rescue and Arrange.
* It remains Pro Discovery gated.
* It does not leak item identities in diagnostics.

---

# Workstream 16.8 — Basic App Intents and Shortcuts Validation

## Goal

Validate basic Shortcuts/App Intents without making automation a main product pillar.

## Basic Supported Actions

Keep visible:

* expand
* collapse
* toggle or reveal all
* show Find Icon
* show Second Bar

Advanced/nested:

* apply profile
* group routes
* spacing preview
* Labs automation
* protected automation
* Smart Triggers

## Tasks

1. Inspect:

* `MenuBar-Manager/Shortcuts/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Profiles/`
* `Settings/Automation`
* App Intent tests

2. Ensure basic intents:

* are discoverable in Shortcuts
* have clear names
* return clear result messages
* respect Safe Mode
* respect automation pause where intended
* do not require Pro unless action needs Pro

3. Ensure advanced intents:

* are nested in Advanced UI
* are Preview
* fail closed
* do not bypass Private Access or Labs gates

4. Add manual QA doc:

`docs/testing/manual-v0.1.3-shortcuts-qa.md`

Manual steps:

* open Shortcuts app
* find MenuBarDeclutter actions
* run expand
* run collapse
* run reveal all
* run show Find Icon
* run show Second Bar
* enable Safe Mode and confirm blocked/degraded behavior

5. Add tests:

* intent execution through Command Center
* Safe Mode gate
* Pro gate
* Labs gate
* automation pause gate
* privacy-safe result

## Acceptance Criteria

* Basic Shortcuts actions work or are clearly documented if manual validation is pending.
* Automation remains advanced, not a main product pillar.
* App Intents do not bypass gates.

---

# Workstream 16.9 — Local Backup and Restore Confidence

## Goal

Make local backup/restore trustworthy enough for v0.1.x users.

This does not mean stable competitor migration.

## Supported Stable/Preview Claims

Stable or near-stable:

* Export Diagnostics
* Export Health Report
* Backup MenuBarDeclutter Settings
* Restore from MenuBarDeclutter backup, if implemented and tested

Preview/Advanced:

* selective import
* profile packs
* group packs
* migration assistant

Deferred:

* stable Bartender/Ice/SaneBar auto-import

## Tasks

1. Inspect:

* `MenuBar-Manager/Migration/`
* `MenuBar-Manager/Core/SettingsStore`
* `MenuBar-Manager/Profiles/`
* `MenuBar-Manager/Groups/`
* `MenuBar-Manager/Hotkeys/`
* `MenuBar-Manager/Layout/`
* `MenuBar-Manager/PrivateAccess/`
* `MenuBar-Manager/Dogfood/`
* `MenuBar-Manager/Diagnostics`

2. Validate export schema:

* app name
* app version
* schema version
* export kind
* redaction mode
* included sections
* created date

3. Validate backup contents:

* settings
* profiles
* groups/collections
* hotkeys
* spacers
* non-sensitive layout preferences
* no active unlock session
* no live search text
* no selected item identity
* protected names redacted unless complete local backup explicitly selected

4. Validate restore behavior:

* dry-run preview
* creates backup before apply
* applies selected sections only
* does not enable risky features by default:

  * Icon Moving
  * Smart Triggers
  * Launch at Login system state
  * Spacing Labs
  * broad automation
* rollback on simulated failure

5. Add tests:

* backup schema
* redaction
* dry-run no mutation
* apply selected sections
* backup-before-restore
* rollback
* risky feature remains disabled after import unless explicitly chosen

6. Update docs:

`docs/support/backup-restore.md`

## Acceptance Criteria

* Local backup/restore is reliable enough for v0.1.3.
* Migration assistant remains Advanced/Preview.
* Competitor import is not claimed stable.
* Privacy-safe export remains safe.

---

# Workstream 16.10 — Developer ID / Notarization Rehearsal

## Goal

Keep the release pipeline ready for a future public distribution/design release by rehearsing notarized distribution if credentials are available.

This phase should not block on credentials, but scripts and docs must remain ready.

## Tasks

1. Inspect:

* `Config/ExportOptions.plist`
* `scripts/build_release.sh`
* `scripts/release_archive.sh`
* `scripts/release_export_app.sh`
* `scripts/release_notarize.sh`
* `scripts/release_staple.sh`
* `scripts/release_validate_gatekeeper.sh`
* `scripts/verify_release_artifact.sh`
* `scripts/verify_installed_app.sh`

2. Run dry-run release.

3. If Developer ID credentials are available:

Run real flow:

```bash
scripts/build_release.sh --notarize --staple --install --verify-installed
```

4. If credentials are not available:

* ensure scripts fail clearly
* update docs to state external blocker
* do not fake notarization success

5. Verify:

* codesign strict
* hardened runtime
* sandbox
* LSUIElement
* app category
* URL scheme
* no network entitlement
* no sensitive usage strings
* no ScreenCaptureKit linkage
* spctl, only if notarized
* stapler, only if stapled

6. Update:

`docs/release/v0.1.3-release-runbook.md`

## Acceptance Criteria

* Dry-run release passes.
* Real notarization path is ready or executed if credentials exist.
* Missing credentials are clearly documented.
* No secrets are committed.
* Installed-app verification passes.

---

# Workstream 16.11 — Real-World Manual QA Expansion

## Goal

v0.1.3 should have stronger evidence than v0.1.2, especially around competitor-critical workflows.

## Create

* `docs/testing/manual-v0.1.3-system-qa.md`
* `docs/testing/manual-v0.1.3-results.md`
* `docs/testing/manual-v0.1.3-crowded-notch-qa.md`
* `docs/testing/manual-v0.1.3-assisted-move-dogfood.md`
* `docs/testing/manual-v0.1.3-shortcuts-qa.md`

## Required Manual QA Areas

### Core Basic

* command-drag setup
* collapse
* expand
* reveal all
* always-hidden reveal
* auto-rehide
* hover reveal
* Basic hotkey

### Arrange

* guided manual arrangement
* placement planner
* item preference marking
* reset layout
* common mistakes flow

### Find & Rescue

* Find Icon
* Second Bar
* New Item Inbox
* crowded rescue fallback
* open owning app
* stale scan explanation

### Pro Permission

* enable Pro
* enable Discovery
* grant Accessibility
* revoke Accessibility
* restart app
* turn Pro off
* degraded states

### Display / Notch

* notch MacBook
* external monitor
* mirror mode
* switch main display
* auto-hide menu bar
* sleep/wake
* Space changes

### Assisted Move

* dry-run only
* cancel confirmation
* one confirmed move on non-system item
* failure recovery
* system item blocked

### Shortcuts

* run basic intents from Shortcuts app
* verify gated advanced actions

### Installed App

* install to `/Applications`
* Launch at Login
* logout/login
* restart if available
* network watch
* diagnostics export
* Safe Mode

## Acceptance Criteria

* Manual QA results are recorded.
* Stable claims pass or are downgraded.
* Preview/Experimental failures are documented honestly.
* v0.1.3 release checklist links to QA docs.

---

# Workstream 16.12 — v0.1.3 Docs and Public Claims

## Goal

Make v0.1.3 ready to serve as the foundation before a future public UI/design release.

## Update or Create

* `README.md`
* `docs/release/v0.1.3-release-notes.md`
* `docs/release/v0.1.3-known-limitations.md`
* `docs/release/v0.1.3-public-claims.md`
* `docs/release/v0.1.3-release-checklist.md`
* `docs/features/find-rescue-v0.1.3.md`
* `docs/features/second-bar-v0.1.3.md`
* `docs/features/arrange-v0.1.3.md`
* `docs/features/placement-planner-v0.1.3.md`
* `docs/features/assisted-move-v0.1.3-experimental.md`
* `docs/features/new-item-inbox-v0.1.3.md`
* `docs/features/shortcuts-v0.1.3.md`
* `docs/support/backup-restore.md`
* `docs/support/permissions.md`
* `docs/support/troubleshooting.md`

## Required Product Message

Use this:

> MenuBarDeclutter is a privacy-first menu bar declutter tool. Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, and recover if layout breaks.

## Stable Claims

Allowed stable claims if implemented and tested:

* Basic hide/show/reveal
* guided manual arrangement
* auto-rehide
* hover reveal
* Basic hotkey
* always-hidden zone
* Safe Mode / recovery
* diagnostics export
* privacy boundary
* local backup, if fully tested
* Find Icon reveal/highlight if Pro gates are satisfied
* Second Bar metadata/icon browsing if Pro gates are satisfied

## Preview Claims

* Pro Placement Planner
* New Item Inbox
* collections/groups inside Find & Rescue
* basic Shortcuts actions
* Crowded Rescue fallback if manual QA supports it

## Experimental Claims

* Assisted Move actual execution
* broad item activation if present
* icon moving beyond manual guidance

## Forbidden Claims

Do not claim:

* stable bulk icon moving
* stable broad activation of arbitrary third-party menu extras
* live menu bar pixel capture
* Screen Recording-free visual duplication of real menu icons
* Private Access encryption
* Private Access hiding already-visible third-party icons
* stable competitor migration
* cloud sync
* telemetry
* v0.2

## Acceptance Criteria

* Docs match implementation.
* Docs are honest about Preview/Experimental boundaries.
* No current-facing v0.2 references.
* Public claims are suitable for a future public design release.

---

# Workstream 16.13 — Final Validation

## Required Commands

Run:

```bash
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

If credentials are available, run:

```bash
scripts/build_release.sh --notarize --staple --install --verify-installed
```

If credentials are unavailable, document the blocker and keep dry-run passing.

## Targeted Searches

Run:

```bash
rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true
rg -n "stable automated move|stable icon moving|bulk move|screen capture|pixel capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "Private Access.*encrypt|Private Access.*hide.*third-party|Touch ID.*hide.*visible" README.md docs MenuBar-Manager || true
rg -n "Bartender import|Ice import|SaneBar import|competitor import" README.md docs MenuBar-Manager || true
```

Inspect results manually. Fix current-facing overclaims. Historical docs may remain only if clearly historical.

## Acceptance Criteria

* All required automated tests pass.
* Privacy boundary passes.
* Dry-run release passes.
* Installed-app verification passes.
* Notarized release either passes or is clearly blocked by missing external credentials.
* Manual QA docs are updated.
* v0.1.3 docs are accurate.
* Phase progress file records final results.

---

# v0.1.3 Definition of Done

v0.1.3 is complete when:

1. App version is `0.1.3`.
2. Current-facing docs/UI do not reference v0.2.
3. Find & Rescue is faster, clearer, and better tested.
4. Find Icon ranking and keyboard flows are improved.
5. Second Bar placement and item actions are more reliable.
6. Crowded/notch rescue decision flow is hardened.
7. Guided Arrange and Placement Planner are more useful.
8. Assisted Move remains Experimental but has better dry-run, recovery, and dogfood logging.
9. New Item Inbox is dogfooded and polished.
10. Basic Shortcuts/App Intents are validated or clearly documented.
11. Local backup/restore is more trustworthy.
12. Developer ID/notarization path is rehearsed or clearly blocked by missing credentials.
13. Manual QA is expanded and recorded.
14. Privacy boundary remains intact.
15. Release dry-run and installed-app verification pass.
16. `docs/progress/phase-16-v0.1.3-competitive-core-catch-up.md` includes:

    * summary
    * changed files
    * test results
    * manual QA results
    * notarization status
    * known limitations
    * recommended scope for a future public design release


---

# Suggested Execution Order

## v0.1.3 slices

### v0.1.3-A — Version + Find & Rescue Performance

```markdown
Implement v0.1.3-A only:
- bump version to 0.1.3 build 4
- improve Find Icon ranking, keyboard flows, and privacy-safe performance diagnostics
- add tests
- do not mention v0.2
```

### v0.1.3-B — Second Bar Reliability

```markdown
Implement v0.1.3-B only:
- improve Second Bar placement and item action menu
- route actions through Command Center
- add display/placement tests
- no screenshots or ScreenCaptureKit
```

### v0.1.3-C — Crowded/Notch Rescue

```markdown
Implement v0.1.3-C only:
- harden CrowdedRevealDecisionEngine
- wire it into reveal paths
- add explanation UI
- add tests and manual QA doc
```

### v0.1.3-D — Arrange Planner + Assisted Move Dogfood

```markdown
Implement v0.1.3-D only:
- improve Placement Planner recommendations
- add item preference persistence
- harden Assisted Move dry-run/result/failure recovery
- add privacy-safe dogfood logs
- keep Assisted Move Experimental
```

### v0.1.3-E — New Item Inbox + Shortcuts Validation

```markdown
Implement v0.1.3-E only:
- polish New Item Inbox detection/review/dismiss/reset
- validate basic App Intents and Shortcuts actions
- keep advanced automation nested
- add tests and manual QA docs
```

### v0.1.3-F — Backup/Restore + Release Rehearsal

```markdown
Implement v0.1.3-F only:
- harden local backup/restore
- keep competitor import deferred
- rehearse dry-run release
- run notarization only if credentials are available
- update docs
```

### v0.1.3-G — Final Docs + Validation

```markdown
Implement v0.1.3-G only:
- update v0.1.3 release notes, public claims, known limitations, support docs
- run full validation commands
- record results in phase progress doc
- do not create v0.2 execution content
```
