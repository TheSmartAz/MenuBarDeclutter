# Function Bar Architecture

The Function Bar source area lives in `MenuBar-Manager/FunctionBar/`.

Core pieces:

- `FunctionBarController` owns the app-owned `NSPanel` and SwiftUI content.
- `FunctionBarViewModel` holds visible state, active workspace, available workspaces, resolved items, and feedback.
- `FunctionBarItemResolver` maps `WorkspaceItem` values into renderable `FunctionBarItemModel` values.
- `FunctionBarActionDispatcher` routes command, group, and proxy actions through Command Center or existing safe coordinators.
- `FunctionBarPlacementService` computes display-aware placement without screen capture or private APIs.

Function Bar is gated by Workspaces Preview, Function Bar Preview, and Safe Mode. It does not open automatically at launch.
