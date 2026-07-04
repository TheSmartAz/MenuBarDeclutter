import Foundation

nonisolated enum MenuBarCommandGate: String, Equatable, Hashable, Sendable {
    case safeMode
    case appIntentsEnabled
    case automationPaused
    case profileAutomation
    case labsAutomation
    case proMode
    case accessibilityDiscovery
    case accessibilityPermission
    case featureEnabled
    case labs
    case privateAccess
    case targetAvailable
    case experimentalConfirmation
}

nonisolated struct MenuBarCommandAvailability: Equatable, Sendable {
    let status: MenuBarCommandResultStatus
    let message: String
    let diagnosticReason: String
    let failedGate: MenuBarCommandGate?

    var isAvailable: Bool { status == .success }

    static let available = MenuBarCommandAvailability(
        status: .success,
        message: "Available.",
        diagnosticReason: "available",
        failedGate: nil
    )

    static func unavailable(
        status: MenuBarCommandResultStatus = .unavailable,
        message: String,
        diagnosticReason: String,
        failedGate: MenuBarCommandGate
    ) -> MenuBarCommandAvailability {
        MenuBarCommandAvailability(
            status: status,
            message: message,
            diagnosticReason: diagnosticReason,
            failedGate: failedGate
        )
    }
}

nonisolated enum MenuBarCommandAvailabilityTone: Equatable, Sendable {
    case success
    case warning
    case danger
    case info
    case secondary
}

nonisolated struct MenuBarCommandAvailabilitySummary: Equatable, Sendable {
    let title: String
    let statusText: String
    let detail: String
    let systemImage: String
    let tone: MenuBarCommandAvailabilityTone
    let failedGateText: String?
    let targetKind: String

    init(
        command: MenuBarCommand,
        availability: MenuBarCommandAvailability
    ) {
        self.title = command.action.displayTitle
        self.statusText = availability.status.displayTitle
        self.detail = availability.detailText
        self.systemImage = availability.status.systemImage
        self.tone = availability.status.availabilityTone
        self.failedGateText = availability.failedGate?.displayTitle
        self.targetKind = command.target.diagnosticKind
    }
}

private extension MenuBarCommandAvailability {
    nonisolated var detailText: String {
        guard let failedGate else {
            return message
        }
        return "\(message) Gate: \(failedGate.displayTitle)."
    }
}

private extension MenuBarCommandAction {
    nonisolated var displayTitle: String {
        switch self {
        case .expand:
            "Expand"
        case .collapse:
            "Collapse"
        case .toggle:
            "Toggle Visibility"
        case .revealAll:
            "Reveal All"
        case .revealHiddenZone:
            "Reveal Hidden Zone"
        case .revealAlwaysHiddenZone:
            "Reveal Always-Hidden Zone"
        case .showFindIcon:
            "Find Icon"
        case .showSecondBar:
            "Second Bar"
        case .hideSecondBar:
            "Hide Second Bar"
        case .showIconPanel:
            "Icon Panel"
        case .showItemInSecondBar:
            "Show Item in Second Bar"
        case .revealItem:
            "Reveal Item"
        case .highlightItem:
            "Highlight Item"
        case .openOwningApp:
            "Open Owning App"
        case .showGroupPanel:
            "Group Panel"
        case .revealGroup:
            "Reveal Group"
        case .createGroupFromItem:
            "Create Group from Item"
        case .addItemToGroup:
            "Add Item to Group"
        case .removeItemFromGroup:
            "Remove Item from Group"
        case .assignHotkey:
            "Assign Hotkey"
        case .protectResource:
            "Protect Resource"
        case .unlockProtectedAction:
            "Unlock Protected Action"
        case .applyProfile:
            "Apply Profile"
        case .dryRunProfile:
            "Dry Run Profile"
        case .pauseAutomation:
            "Pause Automation"
        case .resumeAutomation:
            "Resume Automation"
        case .showLayoutSuggestions:
            "Layout Suggestions"
        case .enterFullMenuBarMode:
            "Enter Full Menu Bar Mode"
        case .exitFullMenuBarMode:
            "Exit Full Menu Bar Mode"
        case .spacingPresetDryRun:
            "Spacing Preset Preview"
        case .spacingPresetApply:
            "Spacing Preset Apply"
        case .dryRunMoveItem:
            "Dry Run Assisted Move"
        case .tryAssistedMoveItem:
            "Try Assisted Move"
        case .cancelAssistedMove:
            "Cancel Assisted Move"
        case .showAssistedMoveGuide:
            "Assisted Move Guide"
        case .experimentalActivateItem:
            "Activate Item"
        case .showWorkspacePreview:
            "Workspace Preview"
        case .switchWorkspace:
            "Switch Workspace"
        case .showFunctionBar:
            "Show Function Bar"
        case .hideFunctionBar:
            "Hide Function Bar"
        case .toggleFunctionBar:
            "Toggle Function Bar"
        case .showInfoStrip:
            "Show Info Strip"
        case .hideInfoStrip:
            "Hide Info Strip"
        case .toggleInfoStrip:
            "Toggle Info Strip"
        case .nextInfoStripTile:
            "Next Info Strip Tile"
        case .openInfoStripSettings:
            "Info Strip Settings"
        case .showFunctionBarFromInfoStrip:
            "Show Function Bar from Info Strip"
        }
    }
}

private extension MenuBarCommandGate {
    nonisolated var displayTitle: String {
        switch self {
        case .safeMode:
            "Safe Mode"
        case .appIntentsEnabled:
            "App Intents"
        case .automationPaused:
            "Automation Pause"
        case .profileAutomation:
            "Profile Automation"
        case .labsAutomation:
            "Labs Automation"
        case .proMode:
            "Optional Pro"
        case .accessibilityDiscovery:
            "Accessibility Discovery"
        case .accessibilityPermission:
            "Accessibility Permission"
        case .featureEnabled:
            "Feature Enabled"
        case .labs:
            "Labs"
        case .privateAccess:
            "Private Access"
        case .targetAvailable:
            "Target Available"
        case .experimentalConfirmation:
            "Labs Confirmation"
        }
    }
}

private extension MenuBarCommandResultStatus {
    nonisolated var displayTitle: String {
        switch self {
        case .success:
            "Available"
        case .unavailable:
            "Unavailable"
        case .blocked:
            "Blocked"
        case .requiresPermission:
            "Permission Needed"
        case .requiresUnlock:
            "Unlock Needed"
        case .requiresPro:
            "Optional Pro Required"
        case .requiresLabs:
            "Labs Required"
        case .dryRunOnly:
            "Preview Only"
        case .failed:
            "Failed"
        case .noOp:
            "No Change"
        }
    }

    nonisolated var systemImage: String {
        switch self {
        case .success:
            "checkmark.circle"
        case .unavailable:
            "slash.circle"
        case .blocked:
            "exclamationmark.octagon"
        case .requiresPermission:
            "hand.raised"
        case .requiresUnlock:
            "lock"
        case .requiresPro:
            "star"
        case .requiresLabs:
            "flask"
        case .dryRunOnly:
            "eye"
        case .failed:
            "xmark.octagon"
        case .noOp:
            "minus.circle"
        }
    }

    nonisolated var availabilityTone: MenuBarCommandAvailabilityTone {
        switch self {
        case .success, .noOp:
            .success
        case .dryRunOnly:
            .info
        case .requiresPro, .requiresPermission, .requiresUnlock, .requiresLabs, .blocked:
            .warning
        case .failed:
            .danger
        case .unavailable:
            .secondary
        }
    }
}
