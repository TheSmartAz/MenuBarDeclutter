import Foundation

@MainActor
protocol MenuBarCommandPrivateAccessChecking: AnyObject {
    func canAccessWithoutPrompt(_ resource: ProtectedResource) -> Bool
}

extension ProtectedActionGate: MenuBarCommandPrivateAccessChecking {}

@MainActor
struct MenuBarCommandHandlers {
    var expand: () -> Void = {}
    var collapse: () -> Void = {}
    var toggle: () -> Void = {}
    var revealAll: () -> Void = {}
    var showFindIcon: () -> Void = {}
    var showSecondBar: () -> Void = {}
    var hideSecondBar: () -> Void = {}
    var showIconPanel: () -> Void = {}
    var showWorkspacePreview: () -> Void = {}
    var switchWorkspace: (UUID) -> Bool = { _ in false }
    var showFunctionBar: () -> Void = {}
    var hideFunctionBar: () -> Void = {}
    var toggleFunctionBar: () -> Void = {}
    var showInfoStrip: () -> Void = {}
    var hideInfoStrip: () -> Void = {}
    var toggleInfoStrip: () -> Void = {}
    var nextInfoStripTile: () -> Void = {}
    var openInfoStripSettings: () -> Void = {}
    var showFunctionBarFromInfoStrip: () -> Void = {}
    var showLayoutSuggestions: () -> Void = {}
    var enterFullMenuBarMode: () -> Void = {}
    var exitFullMenuBarMode: () -> Void = {}
    var previewSpacingPreset: (String) -> Bool = { _ in false }
    var showAssistedMoveGuide: () -> Bool = { false }
    var pauseAutomation: () -> Void = {}
    var resumeAutomation: () -> Void = {}
    var revealItem: (String) -> Bool = { _ in false }
    var highlightItem: (String) -> Bool = { _ in false }
    var openOwningApp: (String) -> Bool = { _ in false }
    var showItemInSecondBar: (String) -> Bool = { _ in false }
    var showGroupPanel: (UUID) -> Bool = { _ in false }
    var revealGroup: (UUID) -> Bool = { _ in false }
    var createGroupFromItem: (String) -> Bool = { _ in false }
    var addItemToGroup: (UUID, String) -> Bool = { _, _ in false }
    var applyProfileNamed: (String) -> Bool = { _ in false }
    var applyProfileID: (UUID) -> Bool = { _ in false }
    var dryRunProfileNamed: (String) -> Bool = { _ in false }
    var dryRunProfileID: (UUID) -> Bool = { _ in false }
}

@MainActor
final class MenuBarCommandRouter {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger?
    private let safeModeActive: () -> Bool
    private let accessibilityStatus: () -> AccessibilityPermissionStatus
    private let privateAccess: (any MenuBarCommandPrivateAccessChecking)?
    private var handlers: MenuBarCommandHandlers

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        safeModeActive: @escaping () -> Bool = { false },
        accessibilityStatus: @escaping () -> AccessibilityPermissionStatus = { .notRequested },
        privateAccess: (any MenuBarCommandPrivateAccessChecking)? = nil,
        handlers: MenuBarCommandHandlers = MenuBarCommandHandlers()
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.safeModeActive = safeModeActive
        self.accessibilityStatus = accessibilityStatus
        self.privateAccess = privateAccess
        self.handlers = handlers
    }

    func route(_ command: MenuBarCommand) -> MenuBarCommandResult {
        let availability = availability(for: command)
        guard availability.isAvailable else {
            let result = MenuBarCommandResult.stopped(
                command,
                status: availability.status,
                message: availability.message,
                diagnosticReason: availability.diagnosticReason
            )
            log(result, source: command.source)
            return result
        }

        let result = execute(command)
        log(result, source: command.source)
        return result
    }

    func availability(for command: MenuBarCommand) -> MenuBarCommandAvailability {
        if command.source == .appIntent, !settingsStore.appIntentsEnabled {
            return .unavailable(
                status: .blocked,
                message: "App Intents are disabled.",
                diagnosticReason: "appIntentsDisabled",
                failedGate: .appIntentsEnabled
            )
        }

        if command.action.blocksInSafeMode, safeModeActive() {
            return .unavailable(
                status: .blocked,
                message: "This command is not available in Safe Mode.",
                diagnosticReason: "safeMode",
                failedGate: .safeMode
            )
        }

        if command.source.isAutomationSource,
           command.action.respectsAutomationPause,
           settingsStore.automationPaused {
            return .unavailable(
                status: .blocked,
                message: "Automation is paused.",
                diagnosticReason: "automationPaused",
                failedGate: .automationPaused
            )
        }

        if command.source.isAutomationSource,
           command.action.requiresProfileAutomationOptIn,
           !settingsStore.appIntentsCanApplyProfiles {
            return .unavailable(
                status: .blocked,
                message: "Profile automation is disabled.",
                diagnosticReason: "profileAutomationDisabled",
                failedGate: .profileAutomation
            )
        }

        if command.source.isAutomationSource,
           command.action.requiresLabsAutomationOptIn,
           !settingsStore.appIntentsCanAccessLabs {
            return .unavailable(
                status: .blocked,
                message: "Labs automation is disabled.",
                diagnosticReason: "labsAutomationDisabled",
                failedGate: .labsAutomation
            )
        }

        if command.action == .revealAlwaysHiddenZone,
           !settingsStore.alwaysHiddenEnabled {
            return .unavailable(
                message: "Always-hidden reveal is disabled.",
                diagnosticReason: "alwaysHiddenDisabled",
                failedGate: .featureEnabled
            )
        }

        if command.action.requiresProMode, !settingsStore.proModeEnabled {
            return .unavailable(
                status: .requiresPro,
                message: "This command requires Pro Mode.",
                diagnosticReason: "proModeDisabled",
                failedGate: .proMode
            )
        }

        if command.action.requiresAccessibilityDiscovery, !settingsStore.accessibilityDiscoveryEnabled {
            return .unavailable(
                status: .requiresPermission,
                message: "This command requires Accessibility Discovery.",
                diagnosticReason: "accessibilityDiscoveryDisabled",
                failedGate: .accessibilityDiscovery
            )
        }

        if command.action.requiresAccessibilityPermission, accessibilityStatus() != .granted {
            return .unavailable(
                status: .requiresPermission,
                message: "This command requires Accessibility permission.",
                diagnosticReason: "accessibilityPermissionMissing",
                failedGate: .accessibilityPermission
            )
        }

        if let feature = command.action.feature,
           !isFeatureEnabled(feature, for: command) {
            return .unavailable(
                status: feature == .spacingLabs ? .requiresLabs : .unavailable,
                message: featureUnavailableMessage(feature),
                diagnosticReason: "\(feature.rawValue)Disabled",
                failedGate: feature == .spacingLabs ? .labs : .featureEnabled
            )
        }

        if command.action == .experimentalActivateItem,
           !command.experimentalConfirmationSatisfied {
            return .unavailable(
                status: .blocked,
                message: "This experimental command requires confirmation.",
                diagnosticReason: "experimentalConfirmationMissing",
                failedGate: .experimentalConfirmation
            )
        }

        if !targetMatchesAction(command) {
            return .unavailable(
                status: .unavailable,
                message: "This command target is unavailable.",
                diagnosticReason: "unsupportedTarget",
                failedGate: .targetAvailable
            )
        }

        if command.source.isAutomationSource,
           let privateAccess,
           !privateAccess.canAccessWithoutPrompt(.appIntent(command.action.rawValue)) {
            return .unavailable(
                status: .requiresUnlock,
                message: "This automation command requires Private Access unlock.",
                diagnosticReason: "privateAccessLocked",
                failedGate: .privateAccess
            )
        }

        if let resource = command.action.privateAccessResource(for: command.target),
           let privateAccess,
           !privateAccess.canAccessWithoutPrompt(resource) {
            return .unavailable(
                status: .requiresUnlock,
                message: "This command requires Private Access unlock.",
                diagnosticReason: "privateAccessLocked",
                failedGate: .privateAccess
            )
        }

        return .available
    }

    private func execute(_ command: MenuBarCommand) -> MenuBarCommandResult {
        switch command.action {
        case .expand:
            handlers.expand()
            return .success(command, message: "Menu bar items expanded.")
        case .collapse:
            handlers.collapse()
            return .success(command, message: "Menu bar items collapsed.")
        case .toggle:
            handlers.toggle()
            return .success(command, message: "Menu bar visibility toggled.")
        case .revealAll, .revealHiddenZone, .revealAlwaysHiddenZone:
            handlers.revealAll()
            return .success(command, message: "Menu bar items revealed.")
        case .showFindIcon:
            handlers.showFindIcon()
            return .success(command, message: "Find Icon opened.")
        case .showSecondBar:
            handlers.showSecondBar()
            return .success(command, message: "Second Bar opened.")
        case .hideSecondBar:
            handlers.hideSecondBar()
            return .success(command, message: "Second Bar hidden.")
        case .showIconPanel:
            handlers.showIconPanel()
            return .success(command, message: "Icon Panel opened.")
        case .showWorkspacePreview:
            handlers.showWorkspacePreview()
            return .success(command, message: "Workspace Preview opened.")
        case .switchWorkspace:
            return executeWorkspace(command)
        case .showFunctionBar:
            handlers.showFunctionBar()
            return .success(command, message: "Function Bar shown.")
        case .hideFunctionBar:
            handlers.hideFunctionBar()
            return .success(command, message: "Function Bar hidden.")
        case .toggleFunctionBar:
            handlers.toggleFunctionBar()
            return .success(command, message: "Function Bar toggled.")
        case .showInfoStrip:
            handlers.showInfoStrip()
            return .success(command, message: "Info Strip shown.")
        case .hideInfoStrip:
            handlers.hideInfoStrip()
            return .success(command, message: "Info Strip hidden.")
        case .toggleInfoStrip:
            handlers.toggleInfoStrip()
            return .success(command, message: "Info Strip toggled.")
        case .nextInfoStripTile:
            handlers.nextInfoStripTile()
            return .success(command, message: "Info Strip advanced to the next tile.")
        case .openInfoStripSettings:
            handlers.openInfoStripSettings()
            return .success(command, message: "Info Strip settings opened.")
        case .showFunctionBarFromInfoStrip:
            handlers.showFunctionBarFromInfoStrip()
            return .success(command, message: "Function Bar shown from Info Strip.")
        case .showLayoutSuggestions:
            handlers.showLayoutSuggestions()
            return .success(command, message: "Layout suggestions opened.")
        case .enterFullMenuBarMode:
            handlers.enterFullMenuBarMode()
            return .success(command, message: "Full Menu Bar Mode entered.")
        case .exitFullMenuBarMode:
            handlers.exitFullMenuBarMode()
            return .success(command, message: "Full Menu Bar Mode exited.")
        case .pauseAutomation:
            handlers.pauseAutomation()
            return .success(command, message: "Automation paused.")
        case .resumeAutomation:
            handlers.resumeAutomation()
            return .success(command, message: "Automation resumed.")
        case .applyProfile:
            return executeProfile(command, dryRun: false)
        case .dryRunProfile:
            return executeProfile(command, dryRun: true)
        case .spacingPresetDryRun:
            return executeSpacingPresetPreview(command)
        case .spacingPresetApply:
            return .stopped(
                command,
                status: .dryRunOnly,
                message: "Spacing preset apply is deferred; preview only.",
                diagnosticReason: "spacingApplyDeferred"
            )
        case .dryRunMoveItem:
            return .success(
                command,
                message: "Assisted Move dry-run generated without moving the item.",
                diagnosticReason: "dryRun"
            )
        case .tryAssistedMoveItem:
            return .stopped(
                command,
                status: .dryRunOnly,
                message: "Assisted Move execution is experimental and handled by the Arrange flow.",
                diagnosticReason: "assistedMoveExecutorPending"
            )
        case .cancelAssistedMove:
            return .stopped(
                command,
                status: .noOp,
                message: "Assisted Move cancelled.",
                diagnosticReason: "cancelled"
            )
        case .showAssistedMoveGuide:
            guard handlers.showAssistedMoveGuide() else {
                return .stopped(
                    command,
                    status: .unavailable,
                    message: "Assisted Move guide is unavailable.",
                    diagnosticReason: "guideUnavailable"
                )
            }
            return .success(command, message: "Assisted Move guide opened.", diagnosticReason: "guide")
        case .revealItem:
            return executeItem(command, message: "Menu bar item revealed.") { id in
                handlers.revealItem(id)
            }
        case .showItemInSecondBar:
            return executeItem(command, message: "Menu bar item shown in Second Bar.") { id in
                handlers.showItemInSecondBar(id)
            }
        case .highlightItem:
            return executeItem(command, message: "Menu bar item highlighted.") { id in
                handlers.highlightItem(id)
            }
        case .openOwningApp:
            return executeItem(command, message: "Owning app opened.") { id in
                handlers.openOwningApp(id)
            }
        case .showGroupPanel:
            return executeGroup(command, message: "Group panel opened.") { id in
                handlers.showGroupPanel(id)
            }
        case .revealGroup:
            return executeGroup(command, message: "Group revealed.") { id in
                handlers.revealGroup(id)
            }
        case .createGroupFromItem:
            return executeItem(command, message: "Group created from item.") { id in
                handlers.createGroupFromItem(id)
            }
        case .addItemToGroup:
            return executeGroupItem(command, message: "Item added to group.") { groupID, itemID in
                handlers.addItemToGroup(groupID, itemID)
            }
        case .removeItemFromGroup, .assignHotkey,
             .protectResource, .unlockProtectedAction,
             .experimentalActivateItem:
            return .stopped(
                command,
                status: .dryRunOnly,
                message: "This command is routed but not wired to an executor yet.",
                diagnosticReason: "executorPending"
            )
        }
    }

    private func executeItem(
        _ command: MenuBarCommand,
        message: String,
        handler: (String) -> Bool
    ) -> MenuBarCommandResult {
        guard case .menuBarItem(let id) = command.target, handler(id) else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Item target is unavailable.",
                diagnosticReason: "itemUnavailable"
            )
        }
        return .success(command, message: message)
    }

    private func executeSpacingPresetPreview(_ command: MenuBarCommand) -> MenuBarCommandResult {
        guard case .spacingPreset(let preset) = command.target else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Spacing preset target is unavailable.",
                diagnosticReason: "spacingPresetUnavailable"
            )
        }

        // Status-menu preview opens the Labs surface only; apply remains dry-run-only.
        guard command.source != .statusMenu || handlers.previewSpacingPreset(preset) else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Spacing preset preview is unavailable.",
                diagnosticReason: "spacingPreviewUnavailable"
            )
        }

        return .success(command, message: "Spacing preset preview generated.", diagnosticReason: "dryRun")
    }

    private func executeGroup(
        _ command: MenuBarCommand,
        message: String,
        handler: (UUID) -> Bool
    ) -> MenuBarCommandResult {
        guard case .group(let id) = command.target, handler(id) else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Group target is unavailable.",
                diagnosticReason: "groupUnavailable"
            )
        }
        return .success(command, message: message)
    }

    private func executeGroupItem(
        _ command: MenuBarCommand,
        message: String,
        handler: (UUID, String) -> Bool
    ) -> MenuBarCommandResult {
        guard case .groupItem(let groupID, let itemID) = command.target,
              handler(groupID, itemID) else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Group item target is unavailable.",
                diagnosticReason: "groupItemUnavailable"
            )
        }
        return .success(command, message: message)
    }

    private func executeProfile(_ command: MenuBarCommand, dryRun: Bool) -> MenuBarCommandResult {
        let didRun: Bool
        switch command.target {
        case .profileName(let name):
            didRun = dryRun ? handlers.dryRunProfileNamed(name) : handlers.applyProfileNamed(name)
        case .profileID(let id):
            didRun = dryRun ? handlers.dryRunProfileID(id) : handlers.applyProfileID(id)
        default:
            didRun = false
        }

        guard didRun else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Profile target is unavailable.",
                diagnosticReason: "profileUnavailable"
            )
        }

        return .success(
            command,
            message: dryRun ? "Profile dry run completed." : "Profile applied.",
            diagnosticReason: dryRun ? "dryRun" : "success"
        )
    }

    private func executeWorkspace(_ command: MenuBarCommand) -> MenuBarCommandResult {
        guard case .workspace(let id) = command.target,
              handlers.switchWorkspace(id) else {
            return .stopped(
                command,
                status: .unavailable,
                message: "Workspace target is unavailable.",
                diagnosticReason: "workspaceUnavailable"
            )
        }
        return .success(command, message: "Workspace switched.")
    }

    private func isFeatureEnabled(_ feature: MenuBarCommandFeature, for command: MenuBarCommand) -> Bool {
        switch feature {
        case .findIcon:
            return true
        case .secondBar:
            return true
        case .iconPanel:
            return false
        case .groups:
            return settingsStore.groupsEnabled
        case .dynamicHotkeys:
            return settingsStore.dynamicHotkeysEnabled
        case .profiles:
            return true
        case .layout:
            return settingsStore.layoutFeaturesEnabled
        case .fullMenuBarMode:
            return settingsStore.layoutFeaturesEnabled && settingsStore.fullMenuBarModeEnabled
        case .layoutSuggestions:
            return settingsStore.layoutFeaturesEnabled && settingsStore.layoutSuggestionsEnabled
        case .spacingLabs:
            return settingsStore.menuBarSpacingLabsEnabled
        case .assistedMove:
            return settingsStore.iconMovingEnabled
        case .workspaces:
            return settingsStore.workspacesPreviewEnabled || command.action == .showWorkspacePreview
        case .functionBar:
            if command.action == .hideFunctionBar {
                return true
            }
            return settingsStore.workspacesPreviewEnabled && settingsStore.functionBarPreviewEnabled
        case .infoStrip:
            if command.action == .hideInfoStrip {
                return true
            }
            return settingsStore.workspacesPreviewEnabled && settingsStore.infoStripPreviewEnabled
        }
    }

    private func featureUnavailableMessage(_ feature: MenuBarCommandFeature) -> String {
        switch feature {
        case .findIcon:
            "Find Icon is unavailable."
        case .secondBar:
            "Second Bar is unavailable."
        case .iconPanel:
            "Icon Panel is not available yet."
        case .groups:
            "Groups are disabled."
        case .dynamicHotkeys:
            "Dynamic Hotkeys are disabled."
        case .profiles:
            "Profiles are unavailable."
        case .layout:
            "Layout features are disabled."
        case .fullMenuBarMode:
            "Full Menu Bar Mode is disabled."
        case .layoutSuggestions:
            "Layout suggestions are disabled."
        case .spacingLabs:
            "Menu Bar Spacing Labs is disabled."
        case .assistedMove:
            "Experimental Icon Moving is disabled."
        case .workspaces:
            "Workspace Preview is disabled."
        case .functionBar:
            "Function Bar Preview is disabled."
        case .infoStrip:
            "Info Strip Preview is disabled."
        }
    }

    private func targetMatchesAction(_ command: MenuBarCommand) -> Bool {
        switch command.action {
        case .applyProfile, .dryRunProfile:
            if case .profileName = command.target { return true }
            if case .profileID = command.target { return true }
            return false
        case .switchWorkspace:
            if case .workspace = command.target { return true }
            return false
        case .showFunctionBar, .hideFunctionBar, .toggleFunctionBar:
            return command.target == .functionBar || command.target == .none
        case .showInfoStrip, .hideInfoStrip, .toggleInfoStrip,
             .nextInfoStripTile, .openInfoStripSettings,
             .showFunctionBarFromInfoStrip:
            return command.target == .infoStrip || command.target == .none
        case .spacingPresetDryRun, .spacingPresetApply:
            if case .spacingPreset = command.target { return true }
            return false
        case .showGroupPanel, .revealGroup:
            if case .group = command.target { return true }
            return false
        case .addItemToGroup, .removeItemFromGroup:
            if case .groupItem = command.target { return true }
            return false
        case .createGroupFromItem:
            if case .menuBarItem = command.target { return true }
            return false
        case .revealItem, .highlightItem, .openOwningApp, .showItemInSecondBar,
             .dryRunMoveItem, .tryAssistedMoveItem, .experimentalActivateItem:
            if case .menuBarItem = command.target { return true }
            return false
        default:
            return true
        }
    }

    private func log(_ result: MenuBarCommandResult, source: MenuBarCommandSource) {
        let level: DiagnosticLevel = result.didRun ? .info : .warning
        diagnosticsLogger?.log(
            "Command Center result: \(result.status.rawValue).",
            level: level,
            category: .urlAutomation,
            metadata: MenuBarCommandDiagnostics.metadata(for: result, source: source)
        )
    }
}

private extension MenuBarCommandSource {
    var isAutomationSource: Bool {
        self == .appIntent || self == .urlAutomation
    }
}
