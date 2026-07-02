import SwiftUI

struct SettingsActions {
    var behaviorChanged: (() -> Void)?
    var searchChanged: (() -> Void)?
    var secondBarChanged: (() -> Void)?
    var privacyChanged: (() -> Void)?
    var groupsChanged: (() -> Void)?
    var dynamicHotkeysChanged: (() -> Void)?
    var automationSettingsChanged: (() -> Void)?
    var commandAvailability: ((MenuBarCommand) -> MenuBarCommandAvailability)?
    var routeCommand: ((MenuBarCommand) -> MenuBarCommandResult)?
    var executeAssistedMove: (@MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)?
    var profile: SettingsProfileActions
    var triggersChanged: (() -> Void)?
    var resetLayout: (() -> Void)?
    var resetAllSettings: (() -> Void)?
    var resetMovingWarnings: (() -> Void)?
    var showOnboarding: (() -> Void)?
    var showDragHint: (() -> Void)?
    var runHealthCheck: (() -> Void)?
    var fixHealthIssues: (() -> Void)?
    var expand: (() -> Void)?
    var revealAll: (() -> Void)?
    var recreateStatusItems: (() -> Void)?
    var disableAutoRehideTemporarily: (() -> Void)?
    var disableHoverRevealTemporarily: (() -> Void)?
    var resetCurrentWorkspaceLayout: (() -> Void)?
    var removeMissingWorkspaceGroupReferences: (() -> Void)?
    var discardSetBuilderDraft: (() -> Void)?
    var disableFunctionBarPreview: (() -> Void)?
    var disableSetBuilderPreview: (() -> Void)?
    var resetBasicMode: (() -> Void)?
    var disableProMode: (() -> Void)?
    var enterSafeModeNextLaunch: (() -> Void)?
    var openTroubleshootingGuide: (() -> Void)?

    init(
        behaviorChanged: (() -> Void)? = nil,
        searchChanged: (() -> Void)? = nil,
        secondBarChanged: (() -> Void)? = nil,
        privacyChanged: (() -> Void)? = nil,
        groupsChanged: (() -> Void)? = nil,
        dynamicHotkeysChanged: (() -> Void)? = nil,
        automationSettingsChanged: (() -> Void)? = nil,
        commandAvailability: ((MenuBarCommand) -> MenuBarCommandAvailability)? = nil,
        routeCommand: ((MenuBarCommand) -> MenuBarCommandResult)? = nil,
        executeAssistedMove: (@MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)? = nil,
        profile: SettingsProfileActions = .empty,
        triggersChanged: (() -> Void)? = nil,
        resetLayout: (() -> Void)? = nil,
        resetAllSettings: (() -> Void)? = nil,
        resetMovingWarnings: (() -> Void)? = nil,
        showOnboarding: (() -> Void)? = nil,
        showDragHint: (() -> Void)? = nil,
        runHealthCheck: (() -> Void)? = nil,
        fixHealthIssues: (() -> Void)? = nil,
        expand: (() -> Void)? = nil,
        revealAll: (() -> Void)? = nil,
        recreateStatusItems: (() -> Void)? = nil,
        disableAutoRehideTemporarily: (() -> Void)? = nil,
        disableHoverRevealTemporarily: (() -> Void)? = nil,
        resetCurrentWorkspaceLayout: (() -> Void)? = nil,
        removeMissingWorkspaceGroupReferences: (() -> Void)? = nil,
        discardSetBuilderDraft: (() -> Void)? = nil,
        disableFunctionBarPreview: (() -> Void)? = nil,
        disableSetBuilderPreview: (() -> Void)? = nil,
        resetBasicMode: (() -> Void)? = nil,
        disableProMode: (() -> Void)? = nil,
        enterSafeModeNextLaunch: (() -> Void)? = nil,
        openTroubleshootingGuide: (() -> Void)? = nil
    ) {
        self.behaviorChanged = behaviorChanged
        self.searchChanged = searchChanged
        self.secondBarChanged = secondBarChanged
        self.privacyChanged = privacyChanged
        self.groupsChanged = groupsChanged
        self.dynamicHotkeysChanged = dynamicHotkeysChanged
        self.automationSettingsChanged = automationSettingsChanged
        self.commandAvailability = commandAvailability
        self.routeCommand = routeCommand
        self.executeAssistedMove = executeAssistedMove
        self.profile = profile
        self.triggersChanged = triggersChanged
        self.resetLayout = resetLayout
        self.resetAllSettings = resetAllSettings
        self.resetMovingWarnings = resetMovingWarnings
        self.showOnboarding = showOnboarding
        self.showDragHint = showDragHint
        self.runHealthCheck = runHealthCheck
        self.fixHealthIssues = fixHealthIssues
        self.expand = expand
        self.revealAll = revealAll
        self.recreateStatusItems = recreateStatusItems
        self.disableAutoRehideTemporarily = disableAutoRehideTemporarily
        self.disableHoverRevealTemporarily = disableHoverRevealTemporarily
        self.resetCurrentWorkspaceLayout = resetCurrentWorkspaceLayout
        self.removeMissingWorkspaceGroupReferences = removeMissingWorkspaceGroupReferences
        self.discardSetBuilderDraft = discardSetBuilderDraft
        self.disableFunctionBarPreview = disableFunctionBarPreview
        self.disableSetBuilderPreview = disableSetBuilderPreview
        self.resetBasicMode = resetBasicMode
        self.disableProMode = disableProMode
        self.enterSafeModeNextLaunch = enterSafeModeNextLaunch
        self.openTroubleshootingGuide = openTroubleshootingGuide
    }

    static let empty = SettingsActions()
}

struct SettingsProfileActions {
    var dryRun: ((ProfileModel) -> ProfileApplicationDryRun)?
    var apply: ((ProfileModel) -> ProfileApplicationDryRun)?

    init(
        dryRun: ((ProfileModel) -> ProfileApplicationDryRun)? = nil,
        apply: ((ProfileModel) -> ProfileApplicationDryRun)? = nil
    ) {
        self.dryRun = dryRun
        self.apply = apply
    }

    static let empty = SettingsProfileActions()
}

@MainActor
extension View {
    func onBehaviorSettingsChanges(
        from settingsStore: SettingsStore,
        perform action: (() -> Void)?
    ) -> some View {
        self
            .forwardSettingsChange(of: settingsStore.autoRehideEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.autoRehideDelaySeconds, to: action)
            .forwardSettingsChange(of: settingsStore.hoverRevealEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.hoverRevealPollingIntervalSeconds, to: action)
            .forwardSettingsChange(of: settingsStore.alwaysHiddenEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.showSeparators, to: action)
            .forwardSettingsChange(of: settingsStore.globalHotkeyEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.globalHotkeyKeyCode, to: action)
            .forwardSettingsChange(of: settingsStore.globalHotkeyModifiersRaw, to: action)
            .forwardSettingsChange(of: settingsStore.revealAllOnOptionClick, to: action)
    }

    func onSearchSettingsChanges(
        from settingsStore: SettingsStore,
        perform action: (() -> Void)?
    ) -> some View {
        self
            .forwardSettingsChange(of: settingsStore.searchEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.searchHotkeyEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.searchHotkeyKeyCode, to: action)
            .forwardSettingsChange(of: settingsStore.searchHotkeyModifiersRaw, to: action)
            .forwardSettingsChange(of: settingsStore.searchRevealOnSelection, to: action)
            .forwardSettingsChange(of: settingsStore.searchHighlightOnSelection, to: action)
    }

    func onSecondBarSettingsChanges(
        from settingsStore: SettingsStore,
        perform action: (() -> Void)?
    ) -> some View {
        self
            .forwardSettingsChange(of: settingsStore.secondBarEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarShowHiddenItems, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarShowAlwaysHiddenItems, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarAutoCloseAfterSelection, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarPositionModeRaw, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarIconSize, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarShowLabels, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarCloseOnOutsideClick, to: action)
            .forwardSettingsChange(of: settingsStore.secondBarActivateOwningAppOnSelection, to: action)
    }

    func onIconMovingSettingsChanges(
        from settingsStore: SettingsStore,
        perform action: (() -> Void)?
    ) -> some View {
        self
            .forwardSettingsChange(of: settingsStore.iconMovingEnabled, to: action)
            .forwardSettingsChange(of: settingsStore.iconMovingRequireConfirmation, to: action)
            .forwardSettingsChange(of: settingsStore.iconMovingMaxRetries, to: action)
            .forwardSettingsChange(of: settingsStore.iconMovingDragDuration, to: action)
            .forwardSettingsChange(of: settingsStore.iconMovingAllowSystemItems, to: action)
    }

    private func forwardSettingsChange<Value: Equatable>(
        of value: Value,
        to action: (() -> Void)?
    ) -> some View {
        onChange(of: value) { _, _ in
            action?()
        }
    }
}
