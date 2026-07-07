# Feature Rationalization — Decision Record (2026-07-07)

**Status:** Active decision record. Sets planning direction beyond the v0.1.10
"everything stays Preview" posture. Does **not** change the current build; it
defines the target the code should be reworked toward.

**Method:** Guided feature audit (grill-me interview) resolving the strategic
decision tree, plus three independent code-truth analyses of the v0.1.10 source
tree (≈66.7k LOC across 249 Swift files, 29 feature subsystems, ~18k test LOC).

---

## TL;DR

A **Pro, Accessibility-required** menu-bar manager whose wedge is **Workspaces** —
*your menu bar shows and hides different real third-party icons per context.* The
atomic operation is **one verified, rollback-safe single-icon move**; everything
else is either the machinery that makes that reliable, the surfaces that expose
it, or supporting cast that must earn its place. The permission-free tier is
retired, but its separator/zone engine survives as the low-level hide mechanism.
No deadline — so the job is **reliability and sequencing, not shipping fast or
cutting deep**.

The one-line problem this record solves: **1 mature feature carrying ~20
half-finished Preview features, none promoted to Stable across 10 releases.**

---

## The seven decisions

| # | Decision | Choice | Key consequence |
|---|----------|--------|-----------------|
| 1 | North Star | **Keep the full vision; consolidate, don't delete** | Removal is limited to genuine dead-ends and redundant overlaps. |
| 2 | Relationship to real icons | **Go all-in on real Accessibility-based control** | The permission-free "don't touch real icons" bet is retired as the product spine. |
| 3 | The wedge (why pick this over free Ice / paid Bartender) | **Workspaces — per-context menu bars** | Most subsystems are re-cast as "in service of Workspaces." |
| 4 | What a workspace switch physically does | **Level 2: per-icon show/hide, each move verified with rollback** | Single-item real move becomes the load-bearing primitive. Bulk reorder stays Deferred. |
| 5 | Fate of permission-free Basic | **Deprecate the *tier*; repurpose the separator engine** | AX required to be useful; `StatusBar/`+`Hiding/` become the hide engine under AX, not a standalone free mode. |
| 6 | Supporting-cast consolidations | **Approved: merge Find Icon→Second Bar; fold Set Builder→Workspaces; demote Info Strip; demote Guided Manual Arrange→fallback** | Removes redundancy/scope-creep without cutting the vision. Spacing stays parked in Labs. |
| 7 | Accurate Icons (Screen-capture thumbnails) | **Defer until the core is reliable** | Ship Second Bar with app-icon fallbacks; no second permission prompt yet. |

### Accepted risk (decision 5, eyes open)
Deprecating the permission-free tier removes the fallback. When Apple breaks AX
drag on an OS update (the synthetic Command-drag path rides entirely undocumented
behavior), the app has **no graceful-degradation path** — it is dead until a
patch ships. This makes two things non-negotiable and part of the foundation, not
polish:
- **Success-rate instrumentation + rollback** on single-item move.
- **A genuine hotfix cadence** for OS point releases.

---

## Code-truth maturity (independent of the decisions above)

From a code-level audit (markers, tests, system-API fragility), *not* the doc
labels. The codebase is clean: zero real TODO/FIXME/stub markers; ~18k test LOC.

- **SOLID (production-grade, low fragility, real tests):** CommandCenter (router),
  Migration/Import-Export, PrivateAccess, the Profiles cluster (Triggers + URL +
  App Intents — the deepest test coverage in the app), WorkspaceIntegration,
  Workspaces, Hotkeys.
- **FUNCTIONAL-BUT-FRAGILE (works, but bound to brittle system behavior):**
  Accessibility/AXScanner, Moving, Second Bar (91 coordinate-math sites), Search,
  Arrange, Groups, Layout, Function Bar, Info Strip.
- **EARLY / SHELL (implemented but unproven):** Accurate Icons
  (`MenuBarIconCapture`) — capture path untested, self-deferred.

**Central irony that drove the plan:** Workspaces is one of the *most* solid,
lowest-fragility subsystems — **precisely because it is pure app-owned config that
touches nothing real** (its own settings copy: *"Switch local Workspace records
without moving real menu bar icons"*). Decision 4 deliberately bolts the shakiest
primitive (single-item synthetic drag) underneath it, so the reliability work in
decision 5's risk note is the real project.

---

## Disposition map (all feature subsystems)

Format: **Subsystem** (code maturity) → disposition — rationale.

### The spine — invest hard
- **Workspaces** (SOLID as config) → **REWORK + INVEST** — the wedge. Rework
  `WorkspaceSwitchingService` from config-only to driving Level-2 real moves.
- **Moving / `IconMoveService`** (fragile) → **INVEST (promote to core)** — single
  item is the atomic op of every switch. Add success-rate telemetry + rollback.
  Bulk (`stableBulkMoving`) stays **Deferred**.
- **Accessibility / AXScanner** (fragile) → **HARDEN** — discovery foundation;
  must survive macOS 26 geometry/notch/off-screen frames.
- **StatusBar/ + Hiding/** (SOLID) → **REWORK/REPURPOSE** — the separator/zone
  engine becomes the low-level hide target under the AX layer. Not deleted.
- **SecondBar** (fragile, 91 coord sites) → **INVEST** — the showcase real-hidden-
  items bar. Full panel **absorbs Find Icon** as a list mode.

### Supporting cast — keep, targeted investment
- **Groups** (functional) → **KEEP** — the atomic primitive Workspaces compose.
- **Profiles + Smart Triggers + URL Automation + App Intents** (SOLID) → **KEEP** —
  rebind Profiles to Workspaces + real zone-moves.
- **Hotkeys + Shortcuts** (SOLID) → **KEEP** — distinct input adapters; workspace-
  switch hotkeys matter now.
- **CommandCenter, Migration, WorkspaceIntegration, DesignSystem, App, Core**
  (SOLID) → **KEEP** — infrastructure. The router will centralize the new gates.
- **Layout** (functional) → **KEEP-LOW**, rename toward "Spacing" — Crowded Reveal
  Rescue / Placement Planner / capacity are AX-era helpers, low priority.
- **Arrange** (fragile) → **KEEP** — the planner feeding Moving.

### Safety net — invest MORE (because decision 5 removed the fallback)
- **Health / Recovery / Safe Mode** (SOLID/functional) → **INVEST** — now the only
  net when AX breaks; must detect and repair a scrambled bar.
- **Diagnostics** (SOLID) → **INVEST** — move success-rate telemetry is core.
- **Onboarding + Permissions** → **REWORK** — sell the AX permission first-run, not
  permission-free.

### Consolidate (approved)
- **Search / Find Icon** → **MERGE into Second Bar** (list mode). Redundant Pro
  panels over the same scan/store.
- **SetBuilder** → **FOLD into Workspaces** — it has no store; it is the Workspace
  drag-drop editor, mislabeled as a peer feature.

### Downgrade / freeze
- **InfoStrip** → **DOWNGRADE** — a different product (menu-bar widgets/dashboard),
  not per-context menu bar. Freeze; revisit only on a glanceable-info pivot.
- **FunctionBar** → **KEEP-NARROW** — scope tightly to *the workspace switcher
  surface*; freeze feature growth. *(Resolved by inference, not interview — open
  to revision; see Open Questions.)*
- **Guided Manual Arrange** → **DOWNGRADE to fallback** — first-run zone setup +
  the instructions shown when an assisted move fails. No longer a headline.
- **Menu Bar Spacing (Spacing Labs)** → **PARK in Labs** — zero investment.

### Defer / remove
- **Accurate Icons (`MenuBarIconCapture`)** → **DEFER** — app-icon fallbacks for
  now; revisit after single-item move is bulletproof.
- **`visualItemCapture`** (private/offscreen capture) → **REMOVE** — orphaned
  engine; delete to shrink surface.
- **Dead `SettingsSection.behavior` enum** + **`onOpenGroups → .advanced` wiring
  bug** → **CLEAN UP**.
- Minor: `ProductFeatureStatus.experimental` renders title "Labs" (duplicate of
  `.labs`) in `FeatureVisibility.swift` — reconcile when the ledger is next touched.

### Maintenance flag
- **`Settings/` is 15,061 LOC — the single largest subsystem**, larger than the
  features it configures. As consolidations land, this should shrink hard. Watch it.

---

## Direct classification (the six buckets originally asked)

| Bucket | Features |
|--------|----------|
| **Mature** | Workspaces\*, Profiles cluster, CommandCenter, Migration, PrivateAccess, WorkspaceIntegration, Hotkeys |
| **Very early** | Accurate Icons (`MenuBarIconCapture`) — the only genuine EARLY/SHELL |
| **Invest more** | Single-item Moving, Accessibility/AXScanner, Second Bar, Health/Recovery/Diagnostics |
| **Downgrade / freeze** | Info Strip, Guided Manual Arrange, Spacing Labs, Function Bar (narrowed) |
| **Remove / dead code** | `visualItemCapture`, `SettingsSection.behavior`, `onOpenGroups` bug |
| **Rework (wrong path)** | Workspaces switching, StatusBar/Hiding, Onboarding, the app-wide "doesn't move real icons" framing |

\*Mature *as code*, wrong-path *as designed* — the rework is turning config-only
switching into real Level-2 control.

---

## Recommended sequence (foundation-first)

1. **Make one icon move bulletproof** — verify / rollback / instrument
   `IconMoveService`. Nothing else matters until this has a measured success rate.
2. **Harden AX discovery** against macOS 26 geometry, the notch, and off-screen
   item frames.
3. **Rewire Workspaces → Level-2** on top of step 1. The wedge becomes real.
4. **Second Bar polish** (absorb Find Icon) as the surface.
5. **Consolidation + cleanup** — Set Builder fold, dead-code removal, Settings prune.
6. **Then** resume breadth.

---

## The load-bearing risk

100% of the product's risk is concentrated on a single fragile primitive with no
fallback, competing against free Ice and mature Bartender. The threat is not scope
— it is the **OS-compatibility treadmill**. A workspace switch that silently
half-fails and scrambles the user's bar is worse than doing nothing. The entire
moat is *"the moves are reliable."* If reliability instrumentation is not the first
thing built, the vision does not survive the next macOS point release.

---

## Open questions / not yet decided

- **Function Bar** disposition was resolved by inference (narrow to switcher), not
  by interview. Revisit if it should instead be cut or expanded.
- **Monetization model** — a Pro tier exists, but with the permission-free free
  tier deprecated there is no free onboarding tier. Deferred (no near-term ship).
- **When to flip the runtime `FeatureVisibility.swift` ledger** — only as each
  rework actually lands, never ahead of the code. This record is the intent; the
  ledger stays current-state truth.
- **Bulk moving** stays Deferred; only revisit if Level-2 proves insufficient.

---

## How this maps to code

- Runtime status ledger: `MenuBar-Manager/Core/FeatureVisibility.swift` (partial —
  the Workspaces cluster is gated separately via `*PreviewEnabled` flags).
- Spine: `Workspaces/`, `Moving/`, `Accessibility/`, `StatusBar/`, `Hiding/`,
  `SecondBar/`.
- Supporting: `Groups/`, `Profiles/`, `Shortcuts/`, `Hotkeys/`, `CommandCenter/`,
  `Migration/`, `WorkspaceIntegration/`, `Layout/`, `Arrange/`.
- Safety net: `Health/`, `Core/DiagnosticsExporter.swift`, `Onboarding/`,
  `Permissions/`.
- Consolidate/defer/remove targets: `Search/`, `SetBuilder/`, `InfoStrip/`,
  `FunctionBar/`, `MenuBarIconCapture/`.

---

## Execution log — foundation reliability work

Tracks steps 1–3 of the recommended sequence (measure the single-move primitive
before building Workspaces on it). Updated as each step lands.

### Step 1 — Recon of the move engine ✅ (2026-07-07)

**What one move attempt records today.** The engine is well-structured and funnels
every result — skip, cancel, fail, success — through a single method,
`IconMoveService.record(_:dogfoodContext:)` (`Moving/IconMoveService.swift:508`).
That method emits three things:
- **`IconMoveResult`** (`Moving/IconMoveResult.swift`): `outcome`
  {succeeded, failed, skipped, cancelled}, `command`, `itemName` (display string),
  `error` (12-case `IconMoveError`), `dragPlanSummary`, `verificationSummary`,
  `retries`.
- **`AssistedMoveDogfoodLogEvent`** (`Arrange/AssistedMoveDogfoodLog.swift`):
  `moveAttempted`, `sourceZone`, `targetZone`, `result`, `failureReason`,
  `durationBucket` — pushed to `DiagnosticsLogger` (`.dogfood` / `.iconMove`).
- **`LiveDiagnosticsStatus`** last-move mirror: `lastIconMoveResult`,
  `lastIconMoveError`, plan/verification summaries, `lastIconMoveRetriesCount`.
- Ground truth for "did it land" is **`DragVerificationResult`**
  {succeeded, notFound, wrongZone} (`Moving/DragVerificationService.swift`).

**The single hook:** `record(_:dogfoodContext:)` — one funnel, every path passes
through it with a `dogfoodContext` carrying `moveAttempted` and `startedAt`.

**What's missing to compute a measured success rate:**
1. **Durability.** Everything is ephemeral — in-memory logger events plus a
   last-only `liveStatus`. Nothing accumulates across sessions, so "success rate
   over the last N attempts" is unanswerable after relaunch.
2. **Aggregation.** No type computes attempts, successes, rate, per-app rate,
   per-zone-transition rate, failure-reason histogram, or retry/latency
   distributions. `durationBucket` is emitted but never tallied.
3. **Per-app slice key.** The aggregatable event has zones but **no app identity**,
   yet per-app rate ("Slack 98%, FooClock 40%") is the entire point of the QA
   matrix. Bundle id is privacy-sensitive (the privacy boundary excludes item
   identity from exports) → must be stored **local-only** and redacted on export.
4. **Coarse latency only.** `record()` computes real elapsed seconds, then throws
   them into 3 buckets (<1s / 1–3s / >3s). No p50/p95 for tuning.
5. **Verification sub-reason flattened.** `.verificationFailed` collapses
   `notFound` (item vanished / re-match failed) and `wrongZone` (landed, wrong
   place) into one code — different diagnoses, same label.
6. **No rate definition.** A meaningful rate is over `moveAttempted == true` only,
   separating **hard failures** (`dragFailed`, `verificationFailed`,
   `planningFailed`, `missingSourceFrame`) from **user/env cancellations**
   (`moveCancelled`, `confirmationCancelled`) and **gating skips** (`disabled`,
   `proModeRequired`, `accessibilityPermissionRequired`).

**Where Step 2 plugs in.** Add a superset value type `MoveOutcome` + a local
`MoveOutcomeStore` (mirror `Dogfood/DogfoodStore.swift`; add a file URL to
`Core/AppSupportPaths.swift`). Inject the store as a sink into `IconMoveService`
at its construction site (`App/MenuBarItemSurfaceCoordinator.swift:119`) and emit
from `record()`. Keep it local-only with a redacted projection; never in the
default diagnostics export.

### Step 2 — Structured `MoveOutcome` instrumentation ✅ (2026-07-07)

Added a durable, privacy-scoped per-attempt record, emitted through the single
`record()` funnel so every skip/cancel/fail/success produces one.

**New code:**
- `Moving/MoveOutcome.swift` — `MoveOutcome` (timestamp, app identity, command
  kind, source/target zone, `moveAttempted`, result, verification, failure
  reason, retries, **real latency in seconds**) plus `MoveCommandKind`,
  `MoveVerificationSummary` (un-flattens `notFound` vs `wrongZone` — Step-1
  finding #5), `IconMoveCommand.kind`, and the `MoveOutcomeRecording` sink
  protocol. Classifiers encode the rate definition: `isReliabilitySample`
  (`moveAttempted` and ran to a succeeded/failed conclusion — excludes gating
  skips and cancellations), `isSuccess`, `isHardFailure`; `redacted` strips
  third-party identity.
- `Moving/MoveOutcomeStore.swift` — local-only, capped (500), atomic JSON store
  (mirrors `DogfoodStore`). Deliberately **not** part of the diagnostics export.

**Wiring & supporting changes:**
- `IconMoveService` builds and emits a `MoveOutcome` from `record()`, threading
  app identity through `IconMoveDogfoodContext` and the verification outcome
  through the fail/cancel/success paths. New `moveOutcomeRecorder` init param
  defaults to `nil` ⇒ **zero production behavior change** in this step.
- Canonical `IconMoveError.diagnosticName` (removed the duplicate private copy in
  `AssistedMoveDogfoodLog`); `IconMoveOutcome: Codable`;
  `AppSupportPaths.moveOutcomesFileURL`.

**Tests (all green):**
- Logic lane (`MenuBarDeclutterLogicTests`, clean build via `xcrun xctest`):
  `MoveOutcomeTests` (classification, redaction, Codable round-trip, latency
  buckets, mappers) and `MoveOutcomeStoreTests` (persist-across-instances,
  retention cap keeps newest, reset) pass; overall 50 tests / 10 suites pass.
- Unit lane (`MenuBarDeclutterTests`): `Suite "Icon Moving Planning"` — 18 tests,
  `** TEST SUCCEEDED **`, including two new emission tests (success + hard
  failure); the 16 pre-existing move-service tests remain green.
- App builds clean (`scripts/build_debug.sh`, exit 0).

**Deferred to Step 3:** wiring `MoveOutcomeStore` into production DI so the app
actually collects during the hardware QA run (it belongs with the aggregation +
matrix that consume it).

### Step 3 — Reliability aggregation, wiring & QA matrix ✅ (2026-07-07)

Turned collected outcomes into a measured success rate with a go/no-go gate, wired
the collector into the live app, and wrote the hardware QA procedure.

**New code:**
- `Moving/MoveReliabilityReport.swift` — pure aggregation from `[MoveOutcome]`:
  overall success rate (over reliability samples only), gate status
  (PASS / FAIL / INSUFFICIENT DATA), per-app and per-zone-transition slices,
  failure histogram, first-attempt rate, latency stats, and a `plainText()`
  readout. Default gate: **≥ 95% success over ≥ 20 samples**.

**Wiring & surface:**
- `MoveOutcomeStore.reliabilityReport(...)` convenience; `persist()` now also
  writes a human-readable `move-reliability.txt` next to `move-outcomes.json`
  (local only) so the QA run has a readout with **no UI**.
- Production DI (the Step-2 deferral): `AppEnvironment` builds `moveOutcomeStore`
  and injects it through `MenuBarItemSurfaceCoordinator` into `IconMoveService`.
  The live app now records one outcome per attempt. Free/basic behavior is
  unchanged — outcomes only fire on attempted assisted moves, already gated
  behind Pro + Accessibility + opt-in.
- Surface choice: a sibling `.txt`, **not** the diagnostics export — the exporter
  is a 1.2k-line, heavily-tested serializer and the report carries per-app
  identity (local only). Kept it out of the export by design.

**QA procedure:**
- `docs/testing/assisted-move-reliability-matrix.md` — app classes × zone
  transitions × display configs (notch / external / multi-display), the gate, and
  where to read the number.

**Tests & build (all green):** logic lane 62 tests / 11 suites pass
(`Move Reliability Report` + `Move Outcome` + `Move Outcome Store`); app builds
clean. Two argument-order mistakes (one in the coordinator's `IconMoveService`
call, one in a test helper call) were caught by the build and fixed — a masked
`echo $?` had briefly hidden the first, now corrected.

### Go / no-go gate for building Workspaces on this

> **PASS = success rate ≥ 95% over ≥ 20 reliability samples** on common
> third-party apps.

- **PASS** → wire Workspaces to Level-2 real moves (roadmap sequence step 3).
- **FAIL** → triage the failing apps/transitions before building on them.
- **INSUFFICIENT DATA** → keep running the matrix.

**Status:** the harness is complete and the live app is collecting. Producing the
actual number requires the hardware QA run — this environment cannot drive real
third-party menu bar icons. Run the matrix, then read
`~/Library/Application Support/MenuBarDeclutter/move-reliability.txt`.

### Gate result — PASS ✅ (2026-07-07)

Hardware QA run returned:

```
Gate: success rate ≥ 95.0% over ≥ 20 samples → PASS
Success rate: 100.0% (20/20)  •  first-attempt 19/20  •  mean 1.03s  •  0 hard failures
```

Cleared to build Workspaces on the primitive. Caveats on record: **20 is the gate
floor** (0 failures in 20 is statistically consistent with a true rate as low as
~85% — a green light, not a guarantee), and the **per-app / per-transition
diversity** of those 20 is still to be confirmed. The collector stays on so the
number self-hardens with use and the first real failure surfaces the failure mode.

### Workspaces Level-2 — kickoff ✅ (2026-07-07)

**Design decisions (locked):**
1. **Target model** — a workspace stores desired zones only for items it has an
   opinion on; items with no opinion are left as-is (never force-hidden); targets
   not currently present are reported unresolved, not treated as failures.
2. **Reconciliation** — move only items whose current zone ≠ desired; order
   **hide-first** (most-hidden target first) to minimize visible-bar thrash and
   keep any partial state on the safer (more-hidden) side.
3. **Rollback** — switch-level **atomic**: if move k of n fails, reverse the k−1
   already applied so a switch is all-or-nothing (honors "don't scramble the bar").
4. **Apply gate + preview** — real moves behind the existing Assisted Move opt-in;
   the plan itself is the dry-run preview shown before anything touches the bar.

**Built (first slice):** `Workspaces/WorkspaceReconciliationPlanner.swift` — a
pure, deterministic planner (scan + target → ordered move plan) with
`unresolved` / `already-satisfied` reporting and `rollbackPlan(afterApplying:)`
for atomic undo. `PlannedMove.command` bridges to the measured `IconMoveService`.

**Verification:** compiles into the app + logic targets (`TEST BUILD SUCCEEDED`),
and all 10 planner scenarios pass. NOTE: the Xcode test *runner* is currently
environment-blocked on clean builds here — `xcrun xctest` fails to load the
freshly-signed `MenuBarDeclutter.debug.dylib` (code-signature load error), which
also hits the pre-existing suites. To confirm the logic despite the blocked
runner, the 10 scenarios were re-run green through the `swift` interpreter against
an inlined copy of the planner. Re-run the normal lane once signing recovers.

**Next slices (not started):**
- (a) **Execution layer** — apply a plan through `IconMoveService` with per-move
  verification and atomic rollback on failure, recording a switch-level outcome.
- (b) **Wire into `WorkspaceSwitchingService`** behind the apply gate.
- (c) **Target model** on `MenuBarWorkspace` / assignments (what each workspace
  stores as desired visibility).
- (d) **Preview UI** for the dry-run plan before applying.
