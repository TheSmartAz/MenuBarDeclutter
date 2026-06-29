# Phase 11 — Private Access & Power User Pack

## Overview

Phase 11 adds private access controls and power-user organization features
without Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring,
network access, telemetry, or cloud sync.

## Features Implemented

### Stable/Optional
- **Icon Groups** — User-created groups that organize menu bar items by
  bundle ID, snapshot ID, title, or zone.
- **Group Panel** — NSPanel + SwiftUI for browsing group items with
  keyboard navigation.
- **Import / Export** — Settings export/import with dry-run, backup,
  conflict detection, and experimental flag safety.
- **Profile Packs** — Reusable profile/group/hotkey packs.

### Power User
- **Per-icon / per-group hotkeys** — Dynamic hotkey bindings with conflict
  detection. All disabled by default.
- **App Intents / Shortcuts** — Shortcuts app integration with
  expand/collapse/reveal/second bar/full menu bar mode/profile/automation
  intents. Respects Safe Mode, pause, and Private Access.

### Private
- **Touch ID / password lock** — LocalAuthentication-based gating for
  protected resources. Off by default. No biometric data stored.

## Non-Goals
- No ScreenCaptureKit.
- No screen/pixel capture.
- No AppleScript dictionary.
- No Apple Events.
- No network/cloud sync.
- No telemetry.
- No automatic competitor config scraping.

## Privacy Boundary
- Private Access uses LocalAuthentication only.
- No biometric data is stored.
- Protected item names are redacted in diagnostics exports.
- App Intents honor privacy locks, automation pause, and Pro requirements.
- Import is explicit and user-selected; no automatic scraping.
- No bulk icon moves from groups, profiles, imports, or shortcuts.

## Files
- `Groups/` — Icon group domain model, store, matcher, validation, import/export.
- `PrivateAccess/` — ProtectedResource, policy, AuthenticationService,
  UnlockSession, PrivateAccessCoordinator, ProtectedActionGate.
- `Hotkeys/` — HotkeyAction, HotkeyBinding, HotkeyBindingStore, HotkeyConflictDetector.
- `Shortcuts/` — AppIntentExecutionService, AppIntentResultMapper, App Intents.
- `Migration/` — SettingsExportPackage, SettingsExportService,
  SettingsImportService, ImportBackupService, ProfilePack.
