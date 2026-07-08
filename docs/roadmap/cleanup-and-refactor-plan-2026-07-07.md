# Codebase Cleanup & Refactor Plan (2026-07-07)

**Status:** Active execution plan. Companion to
[`feature-rationalization-2026-07-07.md`](./feature-rationalization-2026-07-07.md):
that record sets *product* direction; this one is the *engineering* cleanup —
dead code, refactoring, and runtime performance — derived from a full audit of
the v0.1.10 source tree (~93k LOC across 366 Swift files).

**Method:** Four parallel code-truth investigations (dead code, Settings/UI
refactoring, architecture/service-layer refactoring, runtime performance), with
the highest-value dead-code and duplication claims independently re-verified by
grep against the tree. All line numbers are as of this date and will drift.

---

## Bottom line

The codebase is **healthy, not rotting**: zero `TODO`/`FIXME`/stub markers, zero
commented-out blocks, ~18k lines of tests, good testability seams already present
(`IconMoveService`, `MenuBarScanCoordinator`), and idle CPU is already low (AX
scans are event-driven, throttled 2s, debounced 250ms, and run off-main). The
problems are three specific shapes:

1. **Structural dead code** — whole orphaned files and a tests-only ledger, not
   scattered dead members.
2. **Incomplete adoption of patterns the codebase already has** — good helpers
   (`JSONCoding`, the command router's gating, existing coordinators) exist but
   ~13–16 sites bypass them.
3. **Two god objects + one misplaced library** carrying disproportionate size.

Project note: the Xcode project uses **synchronized folder groups**
(`PBXFileSystemSynchronizedRootGroup`), so deleting a dead file needs no
`.pbxproj` edit, and **every file under `MenuBar-Manager/` compiles into the
shipping app** — including test doubles that should not ship.

---

## 0. Corrections to the feature-rationalization decision record

The rationalization doc drives cleanup, so fix these first:

| Doc claim | Verified reality |
|---|---|
| "`visualItemCapture` (private/offscreen capture) → REMOVE — orphaned engine" | Only the **ledger enum case** `ProductFeature.visualItemCapture` is dead. The capture engine `MenuBarIconCapture/` (637 LOC) is **live** under a *different* flag `renderedIconCaptureEnabled` (`PrivacySettingsView.swift:223`, driven from `MenuBarItemSurfaceCoordinator.swift:290,353`). That is the "Accurate Icons" subsystem marked **DEFER**, not delete. Do **not** delete the directory. |
| "Dead `SettingsSection.behavior` enum → CLEAN UP" | Not dead — reachable via the command palette ("Hide & Reveal Legacy", `SettingsCommandPaletteIndex.swift:326`) and a UI-test arg; renders the same `BehaviorSettingsView` as `.hideReveal` (`SettingsRootView.swift:544`). It is a **redundant alias**; cleanup = de-duplication, not dead-code removal. |
| "runtime status ledger: `FeatureVisibility.swift`" | `FeatureVisibility.all` is **not read at runtime** — only by `Phase14ProductDietTests`. Production's real directory is a *separate* hard-coded `AdvancedFeatureDirectory` (`AdvancedSettingsView.swift:126`). |

There are **four sources of truth** for feature status: `ProductFeatureStatus`,
`SettingsRootView.FeatureStatus`, the (dead) `WorkspaceIntegrationFeatureStatus`,
and the `AdvancedFeatureDirectory` data. Consolidating them is a real refactor.

---

## 1. Dead code — safe-to-clean review

### Tier A — delete now, zero ripple (~430 LOC, LOW risk)

| File / symbol | LOC | Evidence |
|---|---|---|
| `DesignSystem/SettingsPrimitives.swift` (whole file) | 249 | All 5 types (`SettingsScaffold`, `SettingsSidebar`, `SettingsGroup`, `SettingsRow`…) — zero references anywhere; superseded by `ClearGlass*`. |
| `Settings/LabeledSlider.swift` (whole file) | 98 | `LabeledSlider` — zero references app-wide or in tests. |
| `WorkspaceIntegration/Runtime/WorkspaceIntegrationCoordinator.swift` | 44 | Never constructed; production builds `WorkspaceUsageIndex()` directly (`AppEnvironment.swift:579`). |
| `WorkspaceIntegration/Assignment/WorkspaceAssignmentCommandAdapter.swift` | 22 | Both types reference only each other; 0 prod, 0 test. |
| `FeatureVisibility.features(in:)` | 3 | Never called by app or tests. |

### Tier B — dead types inside live subsystems (~150 LOC, LOW-MED)

Confirm each is not staged for a pending rework before deleting.
- `WorkspaceIntegration/Models/`: `WorkspaceIntegrationFeatureStatus` (3rd duplicate status enum), `WorkspaceReferenceStatus`, `WorkspaceAssignment` struct (**keep** the live sibling `WorkspaceAssignmentTarget`), `WorkspaceCrowdedRescueContext` struct (**keep** the live sibling `CrowdedRescueWorkspaceFallbackPreference`).
- SetBuilder orphans: `SetBuilderCommitService`, `SetBuilderValidationService`, `SetBuilderItemDraft` (`SetBuilderViewModel.swift:448/472`, `SetBuilderModels.swift:24`).
- InfoStrip orphans: `InfoTile`, `InfoStripInteractionMode`, `InfoStripRotationPolicy` (`InfoStripModels.swift:32/162/170`).
- Never-invoked redactors: `FunctionBarDiagnosticsRedactor`, `InfoStripDiagnosticsRedactor`.
- `CompactStripScanStateBadge` dead private view (`SecondBarCompactStripRootView.swift:268`).
- `visualItemCapture` ledger case + its `.all` entry + the one test reference.
- `MockMenuBarSpacingCommandRunner.shouldFailWrites` — flag never set true; 4 dead guard branches.

### Tier C — decisions, not mechanical deletes (~850 LOC, MED)

- **Test doubles shipped in the app binary → move to test target:**
  `MockAuthenticationService` (`PrivateAccess/AuthenticationService.swift:74`),
  `MockMenuBarSpacingCommandRunner`, `ProfilePack.swift` (whole 103-LOC file —
  tests-only).
- **DesignSystem components rendered only by tests:** `StatusBadge`,
  `MenuBarZoneBadge`, `RequirementRow`, `NoticeBanner`, `ToolbarButton` — confirm
  none is slated for imminent UI use, then remove (partial-file edits).
- **Tests-only `FeatureVisibility` ledger (~290 LOC):** decide — promote to the
  real runtime source of truth (wire `AdvancedFeatureDirectory` to it) or delete
  it plus its test. Keep `ProductFeatureStatus` (it is live).
- **WorkspaceIntegration test-only files:** `WorkspacePlacementRecommendationAdapter.swift`
  (92 LOC), `WorkspacePhysicalProfilePlanner.swift` (60 LOC) — may be intended
  future Level-2 prod code; confirm against roadmap before deleting.

### Confirmed bugs (flag while here)

- **`onOpenGroups → .advanced`** (`SettingsRootView.swift:621`): "Open Groups" in
  `NewItemInboxReviewView` lands on **Advanced**. The same callback is *correctly*
  reused by an "Open Advanced" button (`FindAndRescueSettingsView.swift:228`) →
  fix by **splitting into two callbacks** (`onOpenGroups → .groups`,
  `onOpenAdvanced → .advanced`), not by retargeting the one.
- **`.experimental` renders title "Labs"** duplicating `.labs`
  (`FeatureVisibility.swift:65`) — one-line, present in all three status enums.

---

## 2. Refactoring

### Two god objects + one misplaced library

- **`SettingsRootView.swift` (3,153 LOC) — highest-leverage move.** ~2,000 lines
  (1158–3153) are a complete design-system library (~35 `ClearGlass*` structs,
  used by 16 other files) in the wrong file. Cut/paste into
  `DesignSystem/ClearGlass/` → removes ~13% of `Settings/` with **zero behavior
  change**. Also extract the 20-case `detailView(for:)` switch (`:534`) into a
  `SettingsDetailRouter`.
- **`AppEnvironment.swift` (2,809 LOC)** — DI + lifecycle + command-wiring +
  presentation + business logic (~60 services, ~130 methods). Receiving
  coordinators already exist. Priority slices:
  - **R1** collapse the two parallel command-wiring surfaces (`menuBuilder.actions`
    `:363` and `makeCommandHandlers()` `:2436` — already drifting).
  - **R2** move `…ForRecovery`/`…ForHealth` bodies (`:2201-2338`) into
    `AppHealthCoordinator`.
  - **R3** finish `SettingsRuntimeCoordinator` delegation (stragglers at
    `:1602-1630`).
  - Inject an `IntentExecuting` protocol to kill the `AppEnvironment.shared`
    back-reference reached from `Shortcuts/` at **14 sites**.
  - Target: AppEnvironment → ~600 LOC (composition + `start()/stop()` only).
- **`SettingsStore.swift` (1,730 LOC, 79 dependents)** — flat bag of ~120 keys /
  111 `didSet`-persist properties. Slice into per-domain façades over a thin
  backing store, **domain-by-domain as features are reworked** (never big-bang).
- `HealthService.swift` (697) and `DiagnosticsExporter.swift` (1,208) share the
  "every phase in one struct" shape — split per-domain / separate serialization
  from assembly.

### Duplication → canonicalize (verified counts)

| Pattern | Count | Canonical home |
|---|---|---|
| Hand-rolled JSON stores (own encoder/decoder + atomic write + `lastError`) | **16** files roll their own coder vs **3** using `Core/JSONCoding.swift`; **22** atomic-write sites | Generic `CodableFileStore<T>` on `JSONCoding`; convert new `MoveOutcomeStore` first |
| Pro-discovery gate `proModeEnabled && accessibilityDiscoveryEnabled` | **13** verbatim (more with variants) | A `FeatureGate` type — **before** the mandated Pro/AX policy flip |
| Settings "overview strip" wrappers | ~10 near-identical | Call shared `ClearGlassOverviewStrip` directly (~300 LOC) |
| Inspector-panel containers | 3 reimplementations | One `ClearGlassInspectorPanel` (~200 LOC) |
| Toggle-row idiom + divider | 67 control-row / 138 divider sites | `ClearGlassToggleRow` + auto-dividing `ClearGlassRowStack` |
| Setup/permission step rows | 6+ variants | One `ClearGlassStepRow` (reuse `FeedbackPrimitives.RequirementRow`) |

Consolidation math: DS extraction (~2,000) + shared-component dedup (~800) +
Info-Strip-freeze deletions (~400) plausibly takes `Settings/` from 15,061 →
~11,000 LOC, mostly relocation not risky rewrite.

### Consolidation-driven collapses (from the rationalization doc)

- **Search/Find Icon → Second Bar (list mode):** `Search/` (2,309 LOC) folds
  into `SecondBar/`; delete `SearchSettingsView.swift`; simplify FindAndRescue
  routing.
- **Set Builder → Workspaces:** `SetBuilder/` (1,452) relocates under
  `Workspaces/` (mostly relabel).
- **InfoStrip freeze:** delete ~400 LOC of Info Strip mutation logic from
  `WorkspacePreviewSettingsView`.
- **Accurate Icons defer:** `accurateIconsSection` in `PrivacySettingsView:206`
  becomes inert/removable.

---

## 3. Performance — ranked hot-path fixes

- **H1 (HIGH) — main-thread PNG encode + sync disk write per captured icon.**
  `MenuBarRenderedIconCache.cache()` (`:57→103→122`) is `@MainActor` and runs
  `pngData()` + `write(to:.atomic)` per icon, up to 40 per sweep, synchronously —
  visible hitch on every Second Bar open / surface refresh. Fix: keep in-memory
  update + notification on-main; move encode+write to a background task; coalesce
  to one notification per sweep.
- **H2 (HIGH) — compact strip rebuilds a fresh `NSHostingController` every
  render** (`SecondBarCompactStripWindowController.swift:236`) — twice per open +
  on every reposition. Every other controller reuses one. Fix: create it lazily
  once, then update `rootView` in place.
- **M1 (MED) — hover-reveal timer fires 4 Hz (min 20 Hz) continuously even while
  expanded** (`HoverRevealController.swift:70`); each tick a no-op. Drive from
  collapse-state transitions.
- **M2 (MED) — `TriggerService.currentContext()` rebuilds a Set of all running
  apps' bundle IDs on every app-switch burst** (`:363`); compute lazily only when
  a rule needs it.
- **M3 (MED) — `SearchRootView` polls at 1 Hz while open** (`:133`); it already
  has the change signals to be event-driven.

Confirmed non-issues (already optimized): off-main AX traversal with depth/element
caps + candidate cache; cached screen geometry; the "91 coordinate-math sites"
run only on show/refresh/reposition, not per-frame; no periodic full-rescan timer;
no `DispatchQueue.*.sync`.

---

## 4. Proposed execution — sequenced waves (file-ownership, build-gated)

Rationale: the big targets (`SettingsRootView`, `AppEnvironment`, `SettingsStore`,
`SecondBarCompactStripWindowController`) are each touched by multiple items, so
**naive full-parallel would conflict**. Waves are ordered by dependency;
parallelism is used **only across disjoint file sets within a wave**. Every item:
build (`scripts/build_debug.sh`) + relevant tests + its own commit.

**Wave 1 — zero-risk mechanical, disjoint files (parallel-safe):**
Tier-A deletions · move app-target test doubles to the test target · `.experimental`
label fix. (SettingsRootView edits are handled in Wave 2 to avoid colliding with
the DS extraction.)

**Wave 2 — Settings structural (serial on `SettingsRootView.swift`):**
extract `ClearGlass*` → `DesignSystem/ClearGlass/` · extract `detailView` router ·
`onOpenGroups` callback split · `.behavior` de-dup.

**Wave 3 — canonicalization (parallel across families):**
`CodableFileStore<T>` + convert the 16 stores · `FeatureGate` + route the 13 gate
sites · DesignSystem component dedup (overview strips / inspector panels / toggle
rows).

**Wave 4 — AppEnvironment slimming (serial on `AppEnvironment.swift`):**
R1 dual-command-table collapse · R2 health callbacks → coordinator · R3 settings-
refresh delegation · `IntentExecuting` seam.

**Wave 5 — performance (independent, ship anytime):** H1 · H2 · M1 · M2 · M3.

**Deferred / opportunistic (as features are reworked):** `SettingsStore` façades ·
`DiagnosticsExporter`/`HealthService` splits · Search→SecondBar & SetBuilder→
Workspaces consolidations · Tier-C ledger decision.

### Verification protocol
- After each item: `scripts/build_debug.sh` (exit 0) + the nearest test suite.
- One commit per item, message `cleanup(waveN): <item>`, so any step is
  independently revertible.
- No item spans two waves; no two concurrent items edit the same file.

---

## Execution status (updated 2026-07-08)

**Wave 1 — DONE.**
- Tier-A deletions (~415 LOC): `SettingsPrimitives.swift`, `LabeledSlider.swift`,
  `WorkspaceIntegrationCoordinator.swift`, `WorkspaceAssignmentCommandAdapter.swift`,
  `FeatureVisibility.features(in:)` — commit `af8722d6`.
- `onOpenGroups` / `onOpenAdvanced` callback split (regression fix) — `b682f604`.
- App-shipped test doubles → test target (`MockAuthenticationService`,
  `MockMenuBarSpacingCommandRunner`, `ProfilePack.swift` whole file) moved to
  `MenuBar-ManagerTests/Support/`; verified app build + `build-for-testing` green —
  `da97e0e5`.
- `.experimental` label fix — **skipped** (the "correct" label for `.experimental`
  vs `.labs` is a product decision, not a mechanical fix).

**Wave 2 — DONE.**
- `ClearGlass*` design-system library (~2,000 LOC, 35 types) extracted from
  `SettingsRootView.swift` → `DesignSystem/ClearGlass/ClearGlassComponents.swift` —
  `bbadfe04`.
- `detailView(for:)` 20-case router (~415 LOC) extracted →
  `SettingsRootView+DetailRouter.swift` (same-type extension; 8 private helpers
  promoted to internal) — `0b16d38b`.
- Net: `SettingsRootView.swift` **3,158 → 757 LOC (−76%)**.
- `.behavior` de-dup — satisfied by the existing combined `case .hideReveal,
  .behavior` render (single source of truth). The alias is **kept**: it has a
  production caller (`AppDelegate.swift:252`) + 3 test assertions, and the plan
  scopes this as de-dup, not removal.

**Wave 3 — DONE.**
- `CodableFileStore<T>` primitive — `d8628165` (added standalone, then adopted).
- Adopted across **7 single-file stores** (`MoveOutcomeStore`, `SpacerItemStore`,
  `IconGroupStore`, `MenuBarItemMemoryStore`, `NewMenuBarItemInboxStore`,
  `PlacementItemPreferenceStore`, `WorkspaceStore`) — `e4b9f722`. Each preserves
  its EXACT prior encoder/decoder so on-disk JSON is byte-identical (the
  numeric-`Date` stores keep a plain encoder, NOT the ISO8601 default).
  **`ProfileStore` and `DogfoodStore` intentionally NOT converted** — both are
  multi-file / multi-payload stores that don't fit the single-file primitive.
- Plus **`HotkeyBindingStore`** (`5ffac065`) — a leftover single-file store, same
  shape as the IconGroupStore/SpacerItemStore conversions (single file + Container
  + backup-on-corrupt); completes the sweep to **8 single-file stores**.
  `TriggerService` left as-is (a service with incidental persistence, not a store).
- `FeatureGate` predicate + `SettingsStore.isProDiscoveryAvailable`; routed the
  12 real pro-discovery gate sites (11 settings-backed + 1 snapshot-backed);
  left `HealthService`'s `!proMode && discovery` misconfiguration check
  untouched — `16c0c506`.
- DesignSystem dedup — **`ClearGlassInspectorPanel`** (`a021d416`): merged the
  byte-identical `AdvancedInspectorPanel`/`LayoutInspectorPanel` (12 call sites)
  into one shared DS container; zero rendered change. **Skipped, with reason:**
  the `*OverviewStrip` wrappers (each maps distinct per-screen state to a distinct
  metrics array — inlining relocates code without net reduction and hurts
  readability), the `*InspectorRow` structs (genuinely different value models),
  and `MenuBarInspectorGroup` (a distinct iconless grouping).
- Toggle-row sweep — **DONE.** Added `ClearGlassToggleRow` (collapses
  `ClearGlassControlRow { Toggle().labelsHidden() }`) and `ClearGlassRowStack`
  (auto-inserts dividers between a run of rows, via an isolated `_VariadicView`).
  API piloted on `SearchSettingsView` and approved, then rolled out via parallel
  per-file subagents (strict "correctness over coverage" spec): **23 toggle rows
  collapsed across 6 files; `ClearGlassRowStack` adopted in 7 files.** Converted:
  Search, Layout (13 rows/5 runs), General, SecondBar, Advanced, DynamicHotkeys,
  WorkspacePreview, ProfileList, IconGroups, FindAndRescue. Deliberately NOT
  converted (toggles carrying `.onChange`/`.disabled`/`.help`, Steppers/Pickers,
  or non-literal helper-row runs) — those keep `ClearGlassControlRow`.
  `PrivateAccessSettingsView` had no eligible rows; `AssistedMoveConfirmationView`
  skipped at user request. Each file committed separately; every build green.
- `onChange:` overload added to `ClearGlassToggleRow` → extended sweep collapsed
  **7 more** settings-callback toggles (IconGroups 3, ProfileList 2, Advanced 1,
  DynamicHotkeys 1). **30 toggle rows total.** Left where the closure uses its
  value param (Launch-at-Login, separator-length) or the toggle has
  `.disabled`/HStack (PrivateAccess).
- `ClearGlassStepRow` — consolidated the shared status+action accessory of
  `SearchRequirementRow`, `ProSecondBarSetupStepRow`, `FindRescueSetupStepRow`
  (each keeps its model adapter + own button via a `@ViewBuilder` action slot).
  `ArrangeStepRow`/`RequirementRow`/`DogfoodChecklistRow` left as distinct.
- Skipped, with reason: the `*OverviewStrip` wrappers (distinct per-screen metric
  arrays — inlining is a net loss), `*InspectorRow` structs (different value
  models), `MenuBarInspectorGroup` (distinct chrome).
- **Wave 3 — DONE.** All steps `BUILD SUCCEEDED`; logic lane 107 tests / 20
  suites pass; hosted `HotkeyBindingStore` suite passes.

**Wave 4 — PARTIAL (R3 done; R1/R2 deliberately not done).**
- **R3 — DONE** (`d2b59722`): moved the two straggler refresh methods
  (`refreshGroupSettings`, `refreshDynamicHotkeys`) into
  `SettingsRuntimeCoordinator`, matching their delegated siblings. Threaded the 4
  deps by reference; behavior-identical (`updateLiveStatusFromServices()` ≡
  `liveStatusSynchronizer.synchronize()`); no lazy-init cycle. Build green.
- **R1 — NOT DONE (assessed).** The two command tables are *not* pure duplicates:
  `menuBuilder.actions.revealAll → revealAllFromStatusMenu()` vs
  `handlers.revealAll → revealAllHiddenItems()` (intentional menu-vs-router
  differences). A naive collapse regresses those; the *safe* subset (share the
  byte-identical one-liners) is negligible value. The valuable version — route the
  menu through the command router — is a menu-gating **behavior change**, deferred.
- **R2 — NOT DONE (assessed).** The 15 `…ForRecovery`/`…ForHealth` methods touch
  ~8 subsystems + 5 AppEnvironment call-backs. Moving them wholesale turns
  `AppHealthCoordinator` into a 13-dep hub — relocating coupling, not reducing it —
  at real (unverifiable) regression risk. The existing closure seam is already a
  reasonable abstraction. Deferred.
- Decision (with the user): **bank R3, stop Wave 4.** R1/R2 need a running-app
  smoke-test loop and/or a redesign, not unattended build-only automation.

**Wave 5 — performance — DONE (4 of 5; M3 deliberately skipped).**
- **H1 — DONE** (`9258ad9e`): moved captured-icon PNG encode + atomic write off
  the main actor (a detached utility Task); in-memory cache + per-icon
  notification stay synchronous so consumers see the image immediately. CGImage
  is Sendable; `FileManager.default` used directly. Per-sweep notification
  coalescing left out (no sweep boundary; the userInfo identity is contractual).
- **H2 — DONE** (`974e93bb`): compact strip reuses one `NSHostingController<AnyView>`
  and updates `rootView` in place instead of rebuilding it every render.
- **M1 — DONE** (`4ada968e`): hover-reveal polling timer self-suspends while
  expanded-and-idle and resumes on collapse via `HidingService.onStateChange`
  (previously unused). Reveal/re-hide logic untouched; hover suite passes.
- **M2 — DONE** (`ba568484`): skip enumerating every running app's bundle id
  unless an `.appLaunched` rule exists (its only consumer).
- **M3 — SKIPPED (assessed).** `SearchRootView`'s 1 Hz poll can't be made
  event-driven safely: `refreshProviderBackedResultsIfNeeded()` invalidates on a
  3-part signature including `newItemStorageKeysProvider()` and
  `workspaceUsageProvider()` — both **closures over non-observable sources**, so
  there's no `onChange` signal to drive off (the plan's premise was wrong).
  Removing the poll regresses to stale results; the poll only runs transiently
  while the Search panel is open and is guarded/cheap when nothing changed.

**All cleanup waves resolved.** Waves 1–3 done; Wave 4 = R3 (R1/R2 assessed +
deferred); Wave 5 = H1/H2/M1/M2 (M3 assessed + skipped). Every step build-green;
logic lane 107 tests / 20 suites pass; hosted `HotkeyBindingStore`,
`HoverRevealController`, `MenuBarIconCacheKey` suites pass.
