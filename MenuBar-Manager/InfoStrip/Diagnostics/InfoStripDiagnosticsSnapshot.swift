import Foundation

nonisolated struct InfoStripDiagnosticsSnapshot: Codable, Equatable, Sendable {
    var previewEnabled: Bool
    var autoShowEnabled: Bool
    var isVisible: Bool
    var displayState: String
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var selectedTileProviderCount: Int
    var availableTileProviderCount: Int
    var unavailableTileProviderCount: Int
    var currentTileProviderID: String?
    var rotationIntervalSeconds: Int
    var idleDelaySeconds: Int
    var lastRotationResult: String?
    var lastPlacementMode: String?
    var lastPlacementClamped: Bool
    var lastShowResult: String?

    @MainActor
    static func make(
        settingsStore: SettingsStore,
        controller: InfoStripController?,
        registry: InfoTileProviderRegistry,
        context: InfoTileContext
    ) -> InfoStripDiagnosticsSnapshot {
        let workspace = context.activeWorkspace
        let selected = workspace?.infoStripConfig.selectedTileProviderIDs ?? []
        let availableSelected = selected.reduce(0) { count, providerID in
            guard let provider = registry.provider(id: providerID) else { return count }
            return provider.availability(context: context).isAvailable ? count + 1 : count
        }
        return InfoStripDiagnosticsSnapshot(
            previewEnabled: settingsStore.infoStripPreviewEnabled,
            autoShowEnabled: settingsStore.infoStripAutoShowEnabled,
            isVisible: controller?.displayState.isVisible == true,
            displayState: controller?.displayState.diagnosticName ?? "closed",
            activeWorkspacePresent: workspace != nil,
            activeWorkspaceIDHash: workspace.map { WorkspaceDiagnosticsRedactor.hash(id: $0.id) },
            selectedTileProviderCount: selected.count,
            availableTileProviderCount: availableSelected,
            unavailableTileProviderCount: selected.count - availableSelected,
            currentTileProviderID: controller?.viewModel.currentTile?.providerID,
            rotationIntervalSeconds: workspace?.infoStripConfig.rotationIntervalSeconds ?? 0,
            idleDelaySeconds: workspace?.infoStripConfig.idleDelaySeconds ?? 0,
            lastRotationResult: controller?.lastRotationResult,
            lastPlacementMode: controller?.lastPlacement?.placementMode.rawValue,
            lastPlacementClamped: controller?.lastPlacement?.didClampToVisibleFrame ?? false,
            lastShowResult: controller?.lastShowResult
        )
    }
}

private extension InfoStripDisplayState {
    var isVisible: Bool {
        if case .visible = self { return true }
        return false
    }

    var diagnosticName: String {
        switch self {
        case .closed: "closed"
        case .visible: "visible"
        case .unavailable(let reason): "unavailable.\(reason.rawValue)"
        case .suspendedBySafeMode: "suspendedBySafeMode"
        }
    }
}
