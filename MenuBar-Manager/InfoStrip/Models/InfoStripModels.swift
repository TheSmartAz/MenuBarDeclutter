import Foundation

nonisolated struct InfoTileProviderID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let currentWorkspace = InfoTileProviderID(rawValue: "workspace.current")
    static let clock = InfoTileProviderID(rawValue: "clock.local")
    static let battery = InfoTileProviderID(rawValue: "battery.status")
    static let hiddenCount = InfoTileProviderID(rawValue: "hidden.count")
    static let newItemCount = InfoTileProviderID(rawValue: "newItems.count")
    static let recoveryWarning = InfoTileProviderID(rawValue: "health.warning")
    static let staleScanWarning = InfoTileProviderID(rawValue: "scan.stale")

    var displayName: String {
        switch rawValue {
        case Self.currentWorkspace.rawValue: "Current Workspace"
        case Self.clock.rawValue: "Clock"
        case Self.battery.rawValue: "Battery"
        case Self.hiddenCount.rawValue: "Hidden Count"
        case Self.newItemCount.rawValue: "New Items"
        case Self.recoveryWarning.rawValue: "Recovery Warning"
        case Self.staleScanWarning.rawValue: "Stale Scan"
        default: "Unknown Tile"
        }
    }
}

nonisolated struct InfoTile: Identifiable, Equatable, Sendable {
    var id: InfoTileProviderID
    var displayName: String
    var systemImage: String
}

nonisolated struct InfoTileSnapshot: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var providerID: String
    var title: String
    var subtitle: String?
    var iconName: String
    var severity: InfoTileSeverity
    var timestamp: Date
    var action: InfoTileAction?
    var privacyLevel: InfoTilePrivacyLevel

    init(
        id: UUID = UUID(),
        providerID: String,
        title: String,
        subtitle: String? = nil,
        iconName: String,
        severity: InfoTileSeverity = .normal,
        timestamp: Date,
        action: InfoTileAction? = nil,
        privacyLevel: InfoTilePrivacyLevel = .safeForDiagnostics
    ) {
        self.id = id
        self.providerID = providerID
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.severity = severity
        self.timestamp = timestamp
        self.action = action
        self.privacyLevel = privacyLevel
    }
}

nonisolated enum InfoTileSeverity: String, Codable, Equatable, Sendable {
    case normal
    case info
    case warning
    case critical
}

nonisolated enum InfoTilePermission: String, Codable, Equatable, Sendable {
    case none
    case proDiscovery
    case calendar
    case reminders
    case localAuthentication
    case unavailable
}

nonisolated enum InfoTilePrivacyLevel: String, Codable, Equatable, Sendable {
    case safeForDiagnostics
    case redactedInDiagnostics
    case localOnly
}

nonisolated struct InfoTileAction: Codable, Equatable, Sendable {
    var commandID: String
    var label: String
}

nonisolated enum InfoTileCategory: String, Codable, Equatable, Sendable {
    case workspace
    case time
    case power
    case menuBar
    case health
}

nonisolated enum InfoTileAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
    case permissionRequired(InfoTilePermission)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

nonisolated struct InfoTileContext: Equatable, Sendable {
    var activeWorkspace: MenuBarWorkspace?
    var functionBarVisible: Bool
    var hiddenItemCount: Int?
    var alwaysHiddenItemCount: Int?
    var newItemCount: Int?
    var healthWarningCount: Int
    var latestScanAgeSeconds: Int?
    var proDiscoveryAvailable: Bool
    var safeModeActive: Bool
    var currentDate: Date

    static var empty: InfoTileContext {
        InfoTileContext(
            activeWorkspace: nil,
            functionBarVisible: false,
            hiddenItemCount: nil,
            alwaysHiddenItemCount: nil,
            newItemCount: nil,
            healthWarningCount: 0,
            latestScanAgeSeconds: nil,
            proDiscoveryAvailable: false,
            safeModeActive: true,
            currentDate: Date()
        )
    }
}

nonisolated enum InfoStripDisplayState: Equatable, Sendable {
    case closed
    case visible(workspaceID: UUID, tileProviderID: String?)
    case unavailable(InfoStripUnavailableReason)
    case suspendedBySafeMode
}

nonisolated enum InfoStripUnavailableReason: String, Equatable, Sendable {
    case previewDisabled
    case workspaceDisabled
    case safeModeActive
    case noActiveWorkspace
    case noTilesAvailable
    case noDisplayAvailable
}

nonisolated enum InfoStripInteractionMode: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case showFunctionBarOnHover
    case keepInfoStrip
    case clickToAction

    var id: String { rawValue }
}

nonisolated enum InfoStripRotationPolicy: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case automatic
    case manualOnly

    var id: String { rawValue }
}

nonisolated enum WorkspaceDisplayState: Equatable, Sendable {
    case closed
    case functionBarVisible(workspaceID: UUID)
    case infoStripVisible(workspaceID: UUID, tileID: String?)
    case transitioningToFunctionBar(workspaceID: UUID)
    case transitioningToInfoStrip(workspaceID: UUID)
    case pinnedFunctionBar(workspaceID: UUID)
    case suspendedBySafeMode
    case unavailable(WorkspaceDisplayUnavailableReason)
}

nonisolated enum WorkspaceDisplayUnavailableReason: String, Equatable, Sendable {
    case previewsDisabled
    case noActiveWorkspace
    case safeModeActive
    case infoStripUnavailable
}
