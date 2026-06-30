import Foundation

nonisolated enum MenuBarCommandSource: String, Equatable, Hashable, Sendable {
    case statusMenu
    case settings
    case findIcon
    case secondBar
    case iconPanel
    case groupPanel
    case dynamicHotkey
    case appIntent
    case urlAutomation
    case crowdedRescue
    case internalRecovery
}

nonisolated enum MenuBarCommandFeature: String, Equatable, Hashable, Sendable {
    case findIcon
    case secondBar
    case iconPanel
    case groups
    case dynamicHotkeys
    case profiles
    case layout
    case fullMenuBarMode
    case layoutSuggestions
    case spacingLabs
}

nonisolated enum MenuBarCommandAction: String, CaseIterable, Equatable, Hashable, Sendable {
    case expand
    case collapse
    case toggle
    case revealAll
    case revealHiddenZone
    case revealAlwaysHiddenZone
    case showFindIcon
    case showSecondBar
    case hideSecondBar
    case showIconPanel
    case showItemInSecondBar
    case revealItem
    case highlightItem
    case openOwningApp
    case showGroupPanel
    case revealGroup
    case createGroupFromItem
    case addItemToGroup
    case removeItemFromGroup
    case assignHotkey
    case protectResource
    case unlockProtectedAction
    case applyProfile
    case dryRunProfile
    case pauseAutomation
    case resumeAutomation
    case showLayoutSuggestions
    case enterFullMenuBarMode
    case exitFullMenuBarMode
    case spacingPresetDryRun
    case spacingPresetApply
    case experimentalActivateItem

    var diagnosticName: String { rawValue }

    var blocksInSafeMode: Bool {
        switch self {
        case .pauseAutomation, .resumeAutomation, .exitFullMenuBarMode:
            false
        default:
            true
        }
    }

    var requiresProMode: Bool {
        switch self {
        case .showFindIcon, .showSecondBar, .showIconPanel, .showItemInSecondBar,
             .revealItem, .highlightItem, .openOwningApp, .revealGroup,
             .createGroupFromItem, .addItemToGroup, .removeItemFromGroup, .assignHotkey,
             .experimentalActivateItem:
            true
        default:
            false
        }
    }

    var requiresAccessibilityDiscovery: Bool {
        switch self {
        case .showFindIcon, .showSecondBar, .showIconPanel, .showItemInSecondBar,
             .revealItem, .highlightItem, .openOwningApp, .revealGroup,
             .createGroupFromItem, .addItemToGroup, .removeItemFromGroup, .experimentalActivateItem:
            true
        default:
            false
        }
    }

    var requiresAccessibilityPermission: Bool {
        requiresAccessibilityDiscovery
    }

    var feature: MenuBarCommandFeature? {
        switch self {
        case .showFindIcon:
            .findIcon
        case .showSecondBar, .hideSecondBar, .showItemInSecondBar:
            .secondBar
        case .showIconPanel:
            .iconPanel
        case .showGroupPanel, .revealGroup, .createGroupFromItem, .addItemToGroup, .removeItemFromGroup:
            .groups
        case .assignHotkey:
            .dynamicHotkeys
        case .applyProfile, .dryRunProfile:
            .profiles
        case .showLayoutSuggestions:
            .layoutSuggestions
        case .enterFullMenuBarMode, .exitFullMenuBarMode:
            .fullMenuBarMode
        case .spacingPresetDryRun, .spacingPresetApply:
            .spacingLabs
        default:
            nil
        }
    }

    var respectsAutomationPause: Bool {
        switch self {
        case .pauseAutomation, .resumeAutomation:
            false
        default:
            true
        }
    }

    var requiresProfileAutomationOptIn: Bool {
        switch self {
        case .applyProfile, .dryRunProfile:
            true
        default:
            false
        }
    }

    var requiresLabsAutomationOptIn: Bool {
        switch self {
        case .spacingPresetDryRun, .spacingPresetApply:
            true
        default:
            false
        }
    }

    func privateAccessResource(for target: MenuBarCommandTarget) -> ProtectedResource? {
        switch self {
        case .revealAlwaysHiddenZone:
            return .alwaysHiddenZone
        case .showFindIcon:
            return .findIcon
        case .showSecondBar, .showIconPanel, .showItemInSecondBar:
            return .secondBar
        case .experimentalActivateItem:
            return .iconMoving
        case .spacingPresetApply:
            return .layoutSpacingLabs
        case .applyProfile:
            return .profileApply
        case .showGroupPanel, .revealGroup, .addItemToGroup, .removeItemFromGroup:
            if case .group(let id) = target {
                return .protectedGroup(id)
            }
            if case .groupItem(let id, _) = target {
                return .protectedGroup(id)
            }
            return nil
        case .protectResource, .unlockProtectedAction:
            if case .protectedResource(let resource) = target {
                return resource
            }
            return nil
        default:
            return nil
        }
    }
}

nonisolated struct MenuBarCommand: Equatable, Hashable, Sendable {
    var action: MenuBarCommandAction
    var target: MenuBarCommandTarget
    var source: MenuBarCommandSource
    var experimentalConfirmationSatisfied: Bool

    init(
        action: MenuBarCommandAction,
        target: MenuBarCommandTarget = .none,
        source: MenuBarCommandSource = .settings,
        experimentalConfirmationSatisfied: Bool = false
    ) {
        self.action = action
        self.target = target
        self.source = source
        self.experimentalConfirmationSatisfied = experimentalConfirmationSatisfied
    }
}
