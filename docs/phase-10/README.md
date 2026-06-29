# Phase 10 — Capacity & Layout Pack

## Overview

Phase 10 adds layout and capacity features that help the user fit and access
more menu bar items without Screen Recording, ScreenCaptureKit, Apple Events,
Input Monitoring, network access, telemetry, or cloud sync.

## Features Implemented

### Stable
- **Capacity Estimator** — Estimates menu bar crowding using screen geometry
  (Basic) or AX snapshots (Pro). Works without Accessibility.
- **Full Menu Bar Mode** — Temporary reveal mode that shows all items,
  suspends auto-rehide, and optionally opens Second Bar.
- **Crowded Reveal Rescue** — When inline reveal is likely to fail, opens
  Second Bar or enters Full Menu Bar Mode instead.
- **Spacer / Divider Items** — App-owned NSStatusItem spacers/dividers that
  users can Command-drag. Persists to JSON with corruption recovery.
- **Layout Suggestions** — Non-invasive suggestions based on capacity
  estimates and current settings.

### Labs
- **Menu Bar Spacing Manager** — Experimental, reversible global spacing
  adjustment. Off by default. Backs up before applying. Never restarts
  system processes automatically.

## Non-Goals
- No ScreenCaptureKit.
- No visual pixel capture.
- No Screen Recording permission.
- No Apple Events.
- No Input Monitoring.
- No network.
- No telemetry.
- No automatic icon moving.

## Privacy Boundary

All Phase 10 features are permission-free in Basic Mode. Pro Mode improves
capacity estimates via Accessibility but is optional. No new permissions are
required.

## Files
- `Layout/` module containing all Phase 10 services.
- `Settings/LayoutSettingsView.swift` for the Layout settings tab.
- `Settings/SettingsRootView.swift` updated with `.layout` section.
- `Core/SettingsStore.swift` extended with Phase 10 fields.
- `Core/DiagnosticsLogger.swift` extended with `.layout` category.
- `StatusBar/StatusBarMenuBuilder.swift` extended with layout menu items.
- `Profiles/AutomationURLHandler.swift` extended with layout URL commands.
