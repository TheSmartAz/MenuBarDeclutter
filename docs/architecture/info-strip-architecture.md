# Info Strip Architecture

The Info Strip source area lives in `MenuBar-Manager/InfoStrip/`.

Core pieces:

- `InfoTileProvider` defines local tile providers.
- `InfoTileProviderRegistry` registers and resolves available providers.
- `InfoStripRotationService` rotates selected available provider snapshots.
- `InfoStripController` owns the app-owned `NSPanel`, SwiftUI view model, placement, and rotation lifecycle.
- `InfoStripPlacementService` reuses display-aware placement logic without capture APIs.
- `InfoStripDiagnosticsSnapshot` reports privacy-safe counts and state.

Info Strip is gated by Workspaces Preview, Info Strip Preview, per-Workspace config, and Safe Mode.
