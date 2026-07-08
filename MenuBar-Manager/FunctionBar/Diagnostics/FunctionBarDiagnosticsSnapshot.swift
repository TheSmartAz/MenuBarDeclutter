import Foundation

nonisolated struct FunctionBarDiagnosticsSnapshot: Codable, Equatable, Sendable {
    var previewEnabled: Bool
    var isVisible: Bool
    var displayState: String
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var visibleItemCount: Int
    var commandItemCount: Int
    var proxyItemCount: Int
    var groupItemCount: Int
    var missingReferenceCount: Int
    var unavailableItemCount: Int
    var lastPlacementMode: String?
    var lastPlacementClamped: Bool
    var lastShowResult: String?

    @MainActor
    static func make(
        settingsStore: SettingsStore,
        controller: FunctionBarController?
    ) -> FunctionBarDiagnosticsSnapshot {
        let items = controller?.viewModel.items ?? []
        let activeWorkspace = controller?.viewModel.activeWorkspace
        return FunctionBarDiagnosticsSnapshot(
            previewEnabled: settingsStore.functionBarPreviewEnabled,
            isVisible: controller?.activeState().isVisible == true,
            displayState: controller?.activeState().diagnosticName ?? "closed",
            activeWorkspacePresent: activeWorkspace != nil,
            activeWorkspaceIDHash: activeWorkspace.map { WorkspaceDiagnosticsRedactor.hash(id: $0.id) },
            visibleItemCount: items.count,
            commandItemCount: items.filter { if case .command = $0.kind { true } else { false } }.count,
            proxyItemCount: items.filter { if case .menuBarItem = $0.kind { true } else { false } }.count,
            groupItemCount: items.filter { if case .group = $0.kind { true } else { false } }.count,
            missingReferenceCount: items.filter { $0.status == .missingReference }.count,
            unavailableItemCount: items.filter { !$0.availability.isAvailable }.count,
            lastPlacementMode: controller?.lastPlacement?.placementMode.rawValue,
            lastPlacementClamped: controller?.lastPlacement?.didClampToVisibleFrame ?? false,
            lastShowResult: controller?.lastShowResult
        )
    }
}

private extension FunctionBarDisplayState {
    var diagnosticName: String {
        switch self {
        case .closed: "closed"
        case .opening: "opening"
        case .visible: "visible"
        case .switching: "switching"
        case .unavailable(let reason): "unavailable.\(reason.rawValue)"
        case .suspendedBySafeMode: "suspendedBySafeMode"
        }
    }
}
