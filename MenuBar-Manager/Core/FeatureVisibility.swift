import Foundation

nonisolated enum ProductArea: String, CaseIterable, Identifiable, Sendable {
    case general
    case hideReveal
    case arrange
    case findRescue
    case privacy
    case recovery
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            "General"
        case .hideReveal:
            "Hide & Reveal"
        case .arrange:
            "Arrange"
        case .findRescue:
            "Find & Rescue"
        case .privacy:
            "Privacy"
        case .recovery:
            "Recovery"
        case .advanced:
            "Advanced"
        }
    }
}

nonisolated enum ProductFeatureStatus: String, CaseIterable, Identifiable, Sendable {
    case stable
    case preview
    case labs
    case experimental
    case deferred
    case `internal`

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stable:
            "Stable"
        case .preview:
            "Preview"
        case .labs:
            "Labs"
        case .experimental:
            "Experimental"
        case .deferred:
            "Deferred"
        case .internal:
            "Internal"
        }
    }
}

nonisolated enum ProductFeature: String, CaseIterable, Identifiable, Sendable {
    case basicHideReveal
    case autoRehide
    case hoverReveal
    case basicHotkey
    case alwaysHiddenZone
    case launchAtLogin
    case safeModeRecovery
    case diagnosticsExport
    case privacyBoundary
    case guidedManualArrange
    case placementPlanner
    case findIcon
    case secondBar
    case crowdedRevealRescue
    case newItemInbox
    case lightweightGroups
    case profiles
    case smartTriggers
    case dynamicHotkeys
    case privateAccess
    case appIntents
    case urlAutomation
    case importExport
    case spacingLabs
    case assistedMove
    case broadThirdPartyActivation
    case stableBulkMoving
    case visualItemCapture

    var id: String { rawValue }
}

nonisolated struct FeatureVisibility: Equatable, Sendable {
    let feature: ProductFeature
    let title: String
    let area: ProductArea
    let status: ProductFeatureStatus
    let isVisibleInMainFlow: Bool
    let summary: String

    static let all: [FeatureVisibility] = [
        FeatureVisibility(
            feature: .basicHideReveal,
            title: "Basic Hide & Reveal",
            area: .hideReveal,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Expand, collapse, toggle, and reveal all without sensitive permissions."
        ),
        FeatureVisibility(
            feature: .autoRehide,
            title: "Auto-Rehide",
            area: .hideReveal,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Collapse hidden items again after a short local delay."
        ),
        FeatureVisibility(
            feature: .hoverReveal,
            title: "Hover Reveal",
            area: .hideReveal,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Reveal hidden items while the pointer is near the menu bar."
        ),
        FeatureVisibility(
            feature: .basicHotkey,
            title: "Basic Hotkey",
            area: .hideReveal,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "A simple permission-free shortcut for toggling hidden items."
        ),
        FeatureVisibility(
            feature: .alwaysHiddenZone,
            title: "Always-Hidden Zone",
            area: .hideReveal,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Optional second separator for items that stay hidden during normal reveal."
        ),
        FeatureVisibility(
            feature: .launchAtLogin,
            title: "Launch at Login",
            area: .general,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Start MenuBarDeclutter automatically when the user signs in."
        ),
        FeatureVisibility(
            feature: .safeModeRecovery,
            title: "Safe Mode and Recovery",
            area: .recovery,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Keep the app reachable and repairable when optional features fail."
        ),
        FeatureVisibility(
            feature: .diagnosticsExport,
            title: "Diagnostics Export",
            area: .recovery,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Local support export with redaction by default."
        ),
        FeatureVisibility(
            feature: .privacyBoundary,
            title: "Privacy Boundary",
            area: .privacy,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Basic Mode stays permission-free; Pro features are explicit opt-in."
        ),
        FeatureVisibility(
            feature: .guidedManualArrange,
            title: "Guided Manual Arrange",
            area: .arrange,
            status: .stable,
            isVisibleInMainFlow: true,
            summary: "Teach the user to place controls and separators with normal macOS Command-drag."
        ),
        FeatureVisibility(
            feature: .placementPlanner,
            title: "Placement Planner",
            area: .arrange,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Use Pro Discovery metadata to suggest manual placement without moving items."
        ),
        FeatureVisibility(
            feature: .findIcon,
            title: "Find Icon",
            area: .findRescue,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Locate hidden items from the local discovery index."
        ),
        FeatureVisibility(
            feature: .secondBar,
            title: "Second Bar",
            area: .findRescue,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Browse discovered hidden items in a secondary surface."
        ),
        FeatureVisibility(
            feature: .crowdedRevealRescue,
            title: "Crowded Reveal Rescue",
            area: .findRescue,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Offer a safer fallback when inline reveal is unlikely to fit."
        ),
        FeatureVisibility(
            feature: .newItemInbox,
            title: "New Item Inbox",
            area: .findRescue,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Review newly discovered menu bar items before they get lost."
        ),
        FeatureVisibility(
            feature: .lightweightGroups,
            title: "Collections and Tags",
            area: .findRescue,
            status: .preview,
            isVisibleInMainFlow: true,
            summary: "Use lightweight collections inside item-finding workflows."
        ),
        FeatureVisibility(
            feature: .profiles,
            title: "Profiles",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Power-user saved configurations and profile application."
        ),
        FeatureVisibility(
            feature: .smartTriggers,
            title: "Smart Triggers",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Optional automation for applying profile behavior."
        ),
        FeatureVisibility(
            feature: .dynamicHotkeys,
            title: "Dynamic Hotkeys",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Advanced shortcut bindings beyond the Basic hotkey."
        ),
        FeatureVisibility(
            feature: .privateAccess,
            title: "Private Access",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Local authentication gates for protected app surfaces."
        ),
        FeatureVisibility(
            feature: .appIntents,
            title: "App Intents",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Shortcuts integration for supported command routes."
        ),
        FeatureVisibility(
            feature: .urlAutomation,
            title: "URL Automation",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "URL command routes with the same command gates as the app."
        ),
        FeatureVisibility(
            feature: .importExport,
            title: "Import / Export",
            area: .advanced,
            status: .preview,
            isVisibleInMainFlow: false,
            summary: "Backups and migration assistant flows, nested away from normal use."
        ),
        FeatureVisibility(
            feature: .spacingLabs,
            title: "Spacing Labs",
            area: .advanced,
            status: .labs,
            isVisibleInMainFlow: false,
            summary: "Explicit opt-in spacing experiments kept out of the normal flow."
        ),
        FeatureVisibility(
            feature: .assistedMove,
            title: "Assisted Move",
            area: .arrange,
            status: .experimental,
            isVisibleInMainFlow: true,
            summary: "Single-item confirmed assisted movement; never bulk or silent."
        ),
        FeatureVisibility(
            feature: .broadThirdPartyActivation,
            title: "Broad Third-Party Activation",
            area: .advanced,
            status: .experimental,
            isVisibleInMainFlow: false,
            summary: "Experimental routed activation only when explicitly gated."
        ),
        FeatureVisibility(
            feature: .stableBulkMoving,
            title: "Stable Bulk Moving",
            area: .advanced,
            status: .deferred,
            isVisibleInMainFlow: false,
            summary: "Not part of the v0.1.9 release line."
        ),
        FeatureVisibility(
            feature: .visualItemCapture,
            title: "Visual Item Capture",
            area: .advanced,
            status: .deferred,
            isVisibleInMainFlow: false,
            summary: "Screen capture based workflows are not part of v0.1.9."
        )
    ]

    static func visibility(for feature: ProductFeature) -> FeatureVisibility {
        all.first { $0.feature == feature }!
    }

    static func features(in area: ProductArea) -> [FeatureVisibility] {
        all.filter { $0.area == area }
    }
}
