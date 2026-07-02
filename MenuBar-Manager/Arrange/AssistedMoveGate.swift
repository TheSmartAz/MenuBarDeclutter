import Foundation

nonisolated enum AssistedMoveTargetZone: String, CaseIterable, Identifiable, Sendable {
    case visible
    case hidden
    case alwaysHidden

    var id: String { rawValue }

    var menuBarZone: MenuBarZone {
        switch self {
        case .visible:
            .visible
        case .hidden:
            .hidden
        case .alwaysHidden:
            .alwaysHidden
        }
    }
}

nonisolated enum AssistedMoveGateFailure: String, CaseIterable, Identifiable, Sendable {
    case proModeOff
    case accessibilityDiscoveryOff
    case accessibilityPermissionMissing
    case iconMovingOff
    case safeMode
    case missingFrame
    case invalidTargetZone
    case ownAppItem
    case likelySystemItem
    case firstUseConfirmationMissing
    case perMoveConfirmationMissing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .proModeOff:
            "Pro Mode Required"
        case .accessibilityDiscoveryOff:
            "Accessibility Discovery Required"
        case .accessibilityPermissionMissing:
            "Accessibility Permission Required"
        case .iconMovingOff:
            "Icon Moving Disabled"
        case .safeMode:
            "Safe Mode Active"
        case .missingFrame:
            "Missing Item Frame"
        case .invalidTargetZone:
            "Invalid Target Zone"
        case .ownAppItem:
            "Own App Item Blocked"
        case .likelySystemItem:
            "System Item Blocked"
        case .firstUseConfirmationMissing:
            "First-Use Confirmation Required"
        case .perMoveConfirmationMissing:
            "Move Confirmation Required"
        }
    }
}

nonisolated struct AssistedMoveGateContext: Equatable, Sendable {
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityPermissionGranted: Bool
    let iconMovingEnabled: Bool
    let safeModeActive: Bool
    let allowSystemItems: Bool
    let firstUseConfirmationAccepted: Bool
    let perMoveConfirmationAccepted: Bool
    let appBundleIdentifier: String

    init(
        proModeEnabled: Bool,
        accessibilityDiscoveryEnabled: Bool,
        accessibilityPermissionGranted: Bool,
        iconMovingEnabled: Bool,
        safeModeActive: Bool,
        allowSystemItems: Bool,
        firstUseConfirmationAccepted: Bool,
        perMoveConfirmationAccepted: Bool,
        appBundleIdentifier: String
    ) {
        self.proModeEnabled = proModeEnabled
        self.accessibilityDiscoveryEnabled = accessibilityDiscoveryEnabled
        self.accessibilityPermissionGranted = accessibilityPermissionGranted
        self.iconMovingEnabled = iconMovingEnabled
        self.safeModeActive = safeModeActive
        self.allowSystemItems = allowSystemItems
        self.firstUseConfirmationAccepted = firstUseConfirmationAccepted
        self.perMoveConfirmationAccepted = perMoveConfirmationAccepted
        self.appBundleIdentifier = appBundleIdentifier
    }
}

nonisolated struct AssistedMoveGateResult: Equatable, Sendable {
    let isAvailable: Bool
    let failures: [AssistedMoveGateFailure]

    static let available = AssistedMoveGateResult(isAvailable: true, failures: [])
}

nonisolated struct AssistedMoveGate {
    func evaluate(
        snapshot: MenuBarItemSnapshot,
        targetZone: AssistedMoveTargetZone?,
        context: AssistedMoveGateContext
    ) -> AssistedMoveGateResult {
        var failures: [AssistedMoveGateFailure] = []

        if !context.proModeEnabled {
            failures.append(.proModeOff)
        }

        if !context.accessibilityDiscoveryEnabled {
            failures.append(.accessibilityDiscoveryOff)
        }

        if !context.accessibilityPermissionGranted {
            failures.append(.accessibilityPermissionMissing)
        }

        if !context.iconMovingEnabled {
            failures.append(.iconMovingOff)
        }

        if context.safeModeActive {
            failures.append(.safeMode)
        }

        if snapshot.frame == nil {
            failures.append(.missingFrame)
        }

        if targetZone == nil {
            failures.append(.invalidTargetZone)
        }

        if isOwnItem(snapshot, appBundleIdentifier: context.appBundleIdentifier) {
            failures.append(.ownAppItem)
        }

        if snapshot.isLikelySystemItem && !context.allowSystemItems {
            failures.append(.likelySystemItem)
        }

        if !context.firstUseConfirmationAccepted {
            failures.append(.firstUseConfirmationMissing)
        }

        if !context.perMoveConfirmationAccepted {
            failures.append(.perMoveConfirmationMissing)
        }

        return failures.isEmpty
            ? .available
            : AssistedMoveGateResult(isAvailable: false, failures: failures)
    }

    private func isOwnItem(_ snapshot: MenuBarItemSnapshot, appBundleIdentifier: String) -> Bool {
        if snapshot.bundleIdentifier == appBundleIdentifier {
            return true
        }

        let title = (snapshot.title ?? "").localizedLowercase
        let appName = (snapshot.owningApplicationName ?? "").localizedLowercase
        return title.contains("menubardeclutter") || appName.contains("menubardeclutter")
    }
}
