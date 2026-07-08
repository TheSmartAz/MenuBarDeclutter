# Cleanup + Perf Smoke Test (2026-07-08)

Manual validation for the **behavioral** changes on `assisted-move-reliability-harness`
that a green build can't prove. Run against a fresh local install:

```sh
scripts/build_debug.sh && scripts/release_install_local.sh   # or your usual install path
```

Check each box in the running app. If anything fails, note the commit in parentheses
and stop — that change is independently revertible.

## 1. Hover reveal — the riskiest change (M1, `4ada968e`)

The polling timer now self-suspends while the menu bar is expanded-and-idle and
resumes on collapse. Verify hover still works in every path:

- [ ] Collapse the menu bar. Move the cursor into the menu-bar band → hidden items **reveal**.
- [ ] Move the cursor away → items **re-hide** (with auto-rehide on).
- [ ] **Resume-after-idle:** Reveal All (expand) manually, leave it expanded ~30s, then
      collapse. Now hover the band → items **still reveal** (timer resumed via the
      collapse transition — this is the exact case M1 changed).
- [ ] Toggle **Hover Reveal** off in Settings → hovering does nothing. Toggle back on → works.
- [ ] Diagnostics → **Hover Polling** still shows **Active** while hover is enabled.

## 2. Second Bar rendered-icon capture (H1, `9258ad9e`)

PNG encode + disk write now run off the main actor.

- [ ] Enable rendered/Accurate icon capture (Privacy → rendered capture) with Pro discovery on.
- [ ] Open the Second Bar → captured icons **appear**; opening feels **smoother** (no hitch/stutter
      on a crowded menu bar).
- [ ] Close and reopen the Second Bar → previously captured icons are **still shown** (in-memory)
      and persist across an app relaunch (disk write completed in the background).

## 3. Pro Second Bar compact strip (H2, `974e93bb`)

The strip reuses one hosting controller instead of rebuilding it per render.

- [ ] Open the compact strip → it renders correctly (items, requirements state).
- [ ] Trigger a reposition (move the app / menu bar to another display, or change item set)
      → the strip **updates in place**, no blank frame or visual glitch.
- [ ] Activate an item from the strip → still works; retry/activation feedback shows.

## 4. Smart Triggers (M2, `ba568484`)

Running-app enumeration is skipped unless an `.appLaunched` rule exists.

- [ ] With Smart Triggers on, create an **"App launched"** trigger → it still **fires** when that app launches.
- [ ] A display/battery/time/frontmost trigger (no app-launched rule) still fires normally.

## 5. Settings surfaces — cleanup sanity (Waves 2–3)

The ClearGlass extraction + toggle-row/step-row sweeps touched most settings views.

- [ ] Open every Settings section (General, Hide & Reveal, Arrange, Find & Rescue, Workspaces,
      Layout, Second Bar, Groups, Hotkeys, Advanced, Recovery, Privacy…) → each renders, no blank pane.
- [ ] Toggle a few switches (Auto-rehide, Hover reveal, Enable Groups, Enable Dynamic Hotkeys,
      Enable Smart Triggers) → they persist and their side effects fire (the `onChange` sweep).
- [ ] Find & Rescue setup steps and the Pro Second Bar setup checklist render with status +
      action buttons (the `ClearGlassStepRow` consolidation).
- [ ] "Open Groups" (New Item Inbox) lands on **Groups**, "Open Advanced" lands on **Advanced**
      (the `onOpenGroups`/`onOpenAdvanced` split).

## Sign-off

- [ ] No crashes / assertions during the above.
- [ ] Ready to land.
