Implement Phase 9.4 — Dogfood Bugfix + Stability Sprint.

Context:
Phase 9.3 produced a signed/notarized or dry-run installed alpha workflow. The app is now ready for real dogfood bug fixing. Phase 10 remains deferred.

Phase goal:
Triage dogfood findings, fix stability and correctness bugs, strengthen regression tests, and decide which features remain enabled for v0.1.

Hard constraints:
1. Do not add Phase 10.
2. Do not add ScreenCaptureKit.
3. Do not add Screen Recording permission.
4. Do not add Apple Events.
5. Do not add Input Monitoring.
6. Do not add network access.
7. Do not add telemetry.
8. Do not add new major user-facing features.
9. Prefer bug fixes, diagnostics, tests, and UX clarifications.
10. Basic Mode bugs have highest priority.
11. Icon moving bugs should not block v0.1 unless they affect Basic Mode or safety.
12. Experimental features may be disabled, hidden, or further gated if unstable.
Task 1 — Gather and classify dogfood findings
Create:
- docs/dogfood/phase-9.4-triage.md
- docs/dogfood/phase-9.4-bug-index.md
- docs/dogfood/phase-9.4-risk-board.md

Input sources:
- docs/testing/dogfood/
- docs/testing/phase-9.3-installed-alpha-qa-run.md
- docs/testing/alpha-rc-qa-run-2026-06-28.md
- diagnostics exports.
- health reports.
- manual notes.
- known-risk docs.

Classify issues by area:
1. Basic Mode
2. Status items / separators
3. Auto-rehide / hover
4. Hotkeys
5. Settings / onboarding
6. Launch at Login
7. Pro Accessibility
8. Find Icon
9. Second Bar
10. Icon Moving
11. Profiles / triggers / automation
12. Health / Safe Mode
13. Packaging / signing / notarization
14. Privacy boundary
15. macOS 26 visual behavior
16. external display / notch / sleep-wake / Spaces

Severity:
- S0: data loss / privacy breach / app traps user / menu bar unrecoverable.
- S1: Basic Mode broken.
- S2: installed-app or Launch at Login broken.
- S3: Pro Mode broken but Basic Mode unaffected.
- S4: experimental icon moving issue.
- S5: cosmetic/doc issue.

Release blocking:
- v0.1-blocker
- v0.1-nice-to-fix
- post-v0.1
- won’t fix for now

Acceptance criteria:
- Every dogfood issue is classified.
- Basic Mode blockers are clearly separated from Pro/experimental issues.
- v0.1 release-blocking list exists.
Task 2 — Basic Mode stability fixes
Fix all S0/S1 Basic Mode issues from triage.

Likely areas:
- separator placement and length reapplication.
- collapse/expand state drift.
- always-hidden separator weirdness.
- auto-rehide collapsing too early.
- hover reveal flicker.
- hotkey registration conflicts.
- start-collapsed behavior.
- reset layout behavior.
- sleep/wake/display-change state recovery.
- Safe Mode not exposing reset actions clearly.

Implementation guidance:
- Keep changes minimal.
- Add diagnostics for every fixed failure class.
- Add unit tests for pure logic.
- Add manual QA steps for system behavior.
- If a behavior is inherently unreliable, add a setting to disable it or make it conservative by default.

Acceptance criteria:
- All v0.1-blocking Basic Mode issues are fixed or explicitly converted into known limitations.
- Basic Mode remains permission-free.
- No new privacy permission appears.
- Tests pass.
Task 3 — Launch at Login and installed-app fixes
Fix installed-app issues found in Phase 9.3.

Likely areas:
- SMAppService status stale.
- status display not reflecting System Settings.
- register/unregister error copy unclear.
- installed app path mismatch.
- Launch at Login works from Xcode but not installed app.
- URL scheme points to old build.
- user has multiple app copies installed.

Implement:
1. Better diagnostics for installed app path.
2. Detect multiple installed copies if feasible.
3. Show current bundle path in Diagnostics.
4. Add warning when running from DerivedData/Xcode if testing Launch at Login.
5. Add “Open Installed App Location” if safe.
6. Add “Refresh Login Item Status”.
7. Add docs for stale login item repair.

Acceptance criteria:
- Launch at Login QA is repeatable.
- User can tell whether app is running from Xcode, DerivedData, or /Applications.
- Stale login item repair is documented.
Task 4 — Pro Mode reliability fixes
Fix Pro read-only and assisted-mode dogfood issues.

Scope:
- Accessibility permission grant/revoke.
- scan throttle/debounce.
- stale snapshots.
- incorrect zone classification.
- Find Icon unavailable state.
- highlight overlay wrong screen/frame.
- Second Bar wrong placement.
- Second Bar stale item cache.
- keyboard focus/dismiss behavior.

Rules:
- If Accessibility permission is missing or revoked, degrade clearly.
- Do not crash on AX failures.
- Do not over-poll AX.
- Do not make Pro Mode required for Basic Mode.
- Do not add ScreenCaptureKit.

Acceptance criteria:
- Pro read-only gate passes or remaining failures are documented as known limitations.
- Find Icon and Second Bar fail gracefully without permission.
- AX diagnostics remain privacy-safe.
Task 5 — Experimental icon moving safety pass
Do not try to make icon moving perfect. Make it safer.

Tasks:
1. Review all dogfood icon-moving failures.
2. If any move failure can leave the menu bar in a confusing state, add stronger fail-safe behavior.
3. Improve first-use warning if needed.
4. Improve diagnostics for drag plan, retry, and verification.
5. Add emergency “Reveal All + Reset Separators” action after move failure.
6. Add per-item “not supported” blocking if fixture/real item consistently fails.
7. Consider disabling Move Left/Move Right for v0.1 if they are less reliable than Move to Zone.

Rules:
- Icon moving remains disabled by default.
- Icon moving remains Experimental/Labs.
- Icon moving should not block v0.1 Basic Stable.
- Do not silently run icon moves from profiles/triggers.

Acceptance criteria:
- Icon moving failure is safe.
- Own app/system item protection remains.
- User can recover after failed move.
- v0.1 release notes clearly mark icon moving as experimental or disabled.
Task 6 — Profiles/triggers/automation safety pass
Fix dogfood issues in profiles, triggers, and URL automation.

Tasks:
1. Verify Pause All Automation blocks trigger evaluation and URL profile actions where intended.
2. Verify profile apply remains conservative.
3. Verify triggers do not loop.
4. Verify time/display/app triggers are debounced.
5. Verify Focus/Wi-Fi placeholders are inactive and clearly labeled.
6. Verify URL commands are throttled and command-limited.
7. Add diagnostics for ignored automation due to pause.
8. Add release notes for automation limitations.

Acceptance criteria:
- No trigger can silently run bulk icon moves.
- Pause All Automation is reliable.
- URL automation is local and command-limited.
- Unsafe/incomplete providers are inactive.
Task 7 — Health and Safe Mode hardening
Fix dogfood issues in Health, Recovery, and Safe Mode.

Tasks:
1. Verify crash marker behavior after force quit.
2. Verify clean quit removes marker.
3. Verify Option-at-launch Safe Mode.
4. Verify one-shot Safe Mode flag.
5. Verify Safe Mode disables:
   - auto-rehide
   - hover reveal
   - Pro scans
   - icon moving
   - hotkeys
   - smart triggers
6. Verify Safe Mode still exposes:
   - visible control item
   - Settings
   - Diagnostics
   - Reset Basic Mode
   - Disable Pro Mode
   - Export Health Report
7. Add missing diagnostics or UI copy.

Acceptance criteria:
- Safe Mode is reliable enough to rescue broken app state.
- Recovery never silently resets all settings unless targeted repair fails and user confirms.
Task 8 — Regression tests and QA docs
For every fixed bug:
1. Add or update a unit test if pure logic.
2. Add or update a UI test if stable and not dependent on system permissions.
3. Add manual QA if system-level behavior.
4. Add known limitation if not fixed.

Update:
- docs/testing/dogfood/
- docs/testing/alpha-rc-qa-matrix.md
- docs/testing/installed-app-qa.md
- docs/release/alpha-rc-known-limitations.md
- docs/status/phase-9.4-final-report.md

Acceptance criteria:
- Fixed bugs have regression coverage or manual QA coverage.
- Known limitations are honest.
- QA docs reflect actual behavior.
Task 9 — v0.1 feature gating decision
Create:
- docs/release/v0.1-feature-gates.md

Decide status for each feature:

Stable / enabled:
- Basic Mode collapse/expand.
- reveal all.
- always-hidden if dogfood passed.
- auto-rehide if dogfood passed.
- hover reveal if dogfood passed.
- global hotkey if dogfood passed.
- Settings.
- Onboarding.
- Diagnostics.
- Launch at Login if installed-app QA passed.
- Safe Mode.

Available / optional:
- Pro Accessibility discovery.
- Find Icon.
- Second Bar.
- Profiles basic apply.
- URL automation basic commands.

Experimental / disabled by default:
- icon moving.
- smart triggers.
- profile target-zone moves.
- any partially implemented provider.

Post-v0.1:
- Phase 10 visual icon capture.
- ScreenCaptureKit.
- AppleScript dictionary.
- cloud sync.
- telemetry.

Acceptance criteria:
- v0.1 feature gate doc exists.
- Settings defaults match the feature gate decision.
- Release notes match the feature gate decision.
Task 10 — Final validation commands
Run and record:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. scripts/verify_privacy_boundary.sh
5. scripts/qa_preflight.sh
6. scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app if release artifact exists
7. scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app if installed
8. scripts/qa_dogfood_preflight.sh if Phase 9.2 dogfood harness exists

Update:
- docs/status/phase-9.4-final-report.md

Acceptance criteria:
- All tests pass or failures are documented.
- v0.1 blockers are listed.
- Recommendation for Phase 9.5 is explicit.