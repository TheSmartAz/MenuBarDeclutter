# Phase 19 Progress - v0.1.6 Linked Groups and Set Builder

Date: 2026-07-02

Implemented in the current v0.1.7 worktree.

Evidence:

- `MenuBar-Manager/SetBuilder/` contains models, view model, library providers, drag/drop validation, and SwiftUI views.
- Set Builder is embedded under Advanced Workspaces Preview.
- Workspace drafts can add, remove, reorder, commit, and revert app-owned Function Bar items.
- Linked and detached Group references exist in the model and UI insertion flow.
- Workspace snapshot import/export now preserves Workspaces and linked/detached Group references.

Known follow-up:

- Linked Group warning UX can be made richer in Phase 21 integration work.

Verification:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed on 2026-07-02, including 522 app-unit tests across 75 suites and 16 UI tests.
