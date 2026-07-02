# Profiles

Profiles are local JSON records for saving and applying menu bar layout preferences conservatively.

## What It Does

- Stores profile name, timestamps, preferred visibility state, Second Bar visibility, auto-rehide, hover reveal, bundle-id target zones, and notes.
- Lists profiles from Settings -> Advanced -> Profiles.
- Supports create, duplicate, edit, delete, import, export, dry-run, and apply.
- Applies Basic settings and visibility immediately.
- Produces dry-run summaries for Pro zone moves.
- Records active profile and profile apply logs in Diagnostics.

## User Flow

1. Open Settings -> Advanced -> Profiles.
2. Create or import a profile.
3. Edit visibility, behavior settings, Second Bar visibility, notes, and optional bundle target zones.
4. Use Dry Run to see reveal actions, move previews, unavailable items, and requirements.
5. Use Apply to apply conservative Basic settings.
6. Export profiles as JSON if needed.

## Privacy And Permissions

Profiles are stored locally under `Application Support/MenuBarDeclutter/profiles/`. Normal profile apply does not silently run bulk icon moves. Profile target-zone moves are reported as previews and require separate explicit user action through Icon Moving.

## Implementation

- `MenuBar-Manager/Profiles/ProfileModel.swift`
- `MenuBar-Manager/Profiles/ProfileStore.swift`
- `MenuBar-Manager/Profiles/ProfileApplicationService.swift`
- `MenuBar-Manager/Profiles/ProfileListView.swift`
- `MenuBar-Manager/Profiles/ProfileEditorView.swift`

## Verification

- `MenuBar-ManagerTests/ProfileStoreTests.swift`
- `MenuBar-ManagerTests/ProfileApplicationDryRunTests.swift`
- Manual QA: `docs/testing/manual-v0.1.3-system-qa.md`

## Known Limitations

- Profile target-zone moves are dry-run/report-only during normal apply.
- Corrupted profile JSON is skipped and surfaced through store error state.
- Profiles depend on the latest Accessibility snapshots for move previews.
