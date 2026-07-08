import Foundation

nonisolated enum ProEntitlementState: Equatable, Sendable {
    case basic
    case trialAvailable
    case trialActive(expiration: Date?)
    case licensed
    case expired
    case unavailable

    var isActive: Bool {
        switch self {
        case .trialActive, .licensed:
            true
        case .basic, .trialAvailable, .expired, .unavailable:
            false
        }
    }
}

nonisolated struct ProSecondBarReadinessInput: Equatable, Sendable {
    var entitlement: ProEntitlementState
    var accessibilityDiscoveryEnabled: Bool
    var accessibilityPermission: AccessibilityPermissionStatus
    var accurateIconsEnabled: Bool
    var screenCapturePermission: ScreenCapturePermissionStatus

    init(
        entitlement: ProEntitlementState,
        accessibilityDiscoveryEnabled: Bool,
        accessibilityPermission: AccessibilityPermissionStatus,
        accurateIconsEnabled: Bool,
        screenCapturePermission: ScreenCapturePermissionStatus
    ) {
        self.entitlement = entitlement
        self.accessibilityDiscoveryEnabled = accessibilityDiscoveryEnabled
        self.accessibilityPermission = accessibilityPermission
        self.accurateIconsEnabled = accurateIconsEnabled
        self.screenCapturePermission = screenCapturePermission
    }
}

nonisolated enum ProSecondBarReadinessState: String, Equatable, Sendable {
    case ready
    case missingEntitlement
    case accessibilityDiscoveryDisabled
    case accessibilityPermissionMissing
    case accurateIconsDisabled
    case screenRecordingMissing

    var isReady: Bool { self == .ready }

    var displayTitle: String {
        switch self {
        case .ready:
            "Second Bar Ready"
        case .missingEntitlement:
            "Pro Required"
        case .accessibilityDiscoveryDisabled:
            "Accessibility Discovery Off"
        case .accessibilityPermissionMissing:
            "Accessibility Permission Required"
        case .accurateIconsDisabled:
            "Accurate Icons Required"
        case .screenRecordingMissing:
            "Screen Recording Required"
        }
    }

    var message: String {
        switch self {
        case .ready:
            "Compact Second Bar is ready."
        case .missingEntitlement:
            "Start a trial or activate Pro before setting up Second Bar."
        case .accessibilityDiscoveryDisabled:
            "Enable local Accessibility Discovery to find hidden menu bar items."
        case .accessibilityPermissionMissing:
            "Grant Accessibility permission so Second Bar can find and activate menu bar items."
        case .accurateIconsDisabled:
            "Enable Accurate Icons before using the compact Second Bar."
        case .screenRecordingMissing:
            "Grant Screen Recording permission so Accurate Icons can prepare menu bar thumbnails."
        }
    }
}

nonisolated struct ProSecondBarReadinessResult: Equatable, Sendable {
    let state: ProSecondBarReadinessState
    let entitlement: ProEntitlementState

    var isReady: Bool { state.isReady }
}

nonisolated enum ProSecondBarReadiness {
    static func evaluate(_ input: ProSecondBarReadinessInput) -> ProSecondBarReadinessResult {
        let state: ProSecondBarReadinessState
        if !input.entitlement.isActive {
            state = .missingEntitlement
        } else if !input.accessibilityDiscoveryEnabled {
            state = .accessibilityDiscoveryDisabled
        } else if input.accessibilityPermission != .granted {
            state = .accessibilityPermissionMissing
        } else if !input.accurateIconsEnabled {
            state = .accurateIconsDisabled
        } else if input.screenCapturePermission != .granted {
            state = .screenRecordingMissing
        } else {
            state = .ready
        }

        return ProSecondBarReadinessResult(
            state: state,
            entitlement: input.entitlement
        )
    }
}

nonisolated enum StatusBarPrimaryClickRoute: Equatable, Sendable {
    case toggleInlineVisibility
    case toggleCompactStrip
    case showSecondBarRequirements
}

nonisolated enum StatusBarPrimaryClickRouter {
    static func route(
        entitlement: ProEntitlementState,
        readiness: ProSecondBarReadinessState,
        primaryClickOptIn: Bool,
        safeModeActive: Bool
    ) -> StatusBarPrimaryClickRoute {
        guard !safeModeActive else {
            return .toggleInlineVisibility
        }

        guard entitlement.isActive, primaryClickOptIn else {
            return .toggleInlineVisibility
        }

        return readiness == .ready ? .toggleCompactStrip : .showSecondBarRequirements
    }
}
