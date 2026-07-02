# Workspaces Architecture

The Workspaces foundation lives in `MenuBar-Manager/Workspaces/`.

Core pieces:

- `MenuBarWorkspace` and `WorkspaceItem` define app-owned workspace configuration.
- `WorkspaceStoreSnapshot` and `WorkspaceStore` persist local JSON under Application Support.
- `WorkspaceValidation` repairs invalid names, duplicate item IDs, unsafe counts, active workspace problems, and Info Strip timing bounds.
- `WorkspaceSwitchingService` owns active workspace changes and persistence.
- `WorkspaceDiagnosticsSnapshot` reports privacy-safe counts and redacted identifiers.

The service boundary deliberately avoids physical menu bar mutation. Switching a workspace updates MenuBarDeclutter state only; it does not move icons, apply profiles, open Function Bar, open Info Strip, or prompt for permissions.
