import Foundation

@MainActor
final class AppEnvironmentLiveStatusSynchronizer {
    private let liveStatus: LiveDiagnosticsStatus
    private let settingsStore: SettingsStore
    private let hidingService: HidingService
    private let primarySeparatorController: SeparatorController
    private let alwaysHiddenSeparatorController: SeparatorController
    private let hotkeyManager: GlobalHotkeyManager
    private let hoverRevealController: HoverRevealController
    private let rehideController: RehideController
    private let accessibilityPermissionService: AccessibilityPermissionService

    init(
        liveStatus: LiveDiagnosticsStatus,
        settingsStore: SettingsStore,
        hidingService: HidingService,
        primarySeparatorController: SeparatorController,
        alwaysHiddenSeparatorController: SeparatorController,
        hotkeyManager: GlobalHotkeyManager,
        hoverRevealController: HoverRevealController,
        rehideController: RehideController,
        accessibilityPermissionService: AccessibilityPermissionService
    ) {
        self.liveStatus = liveStatus
        self.settingsStore = settingsStore
        self.hidingService = hidingService
        self.primarySeparatorController = primarySeparatorController
        self.alwaysHiddenSeparatorController = alwaysHiddenSeparatorController
        self.hotkeyManager = hotkeyManager
        self.hoverRevealController = hoverRevealController
        self.rehideController = rehideController
        self.accessibilityPermissionService = accessibilityPermissionService
    }

    func synchronize() {
        liveStatus.applyRuntimeState(
            LiveDiagnosticsRuntimeState(
                visibilityState: hidingService.visibilityState,
                primarySeparatorLength: primarySeparatorController.currentLength,
                alwaysHiddenSeparatorLength: alwaysHiddenSeparatorController.currentLength,
                alwaysHiddenSeparatorInstalled: alwaysHiddenSeparatorController.statusItem != nil,
                hotkeyRegistered: hotkeyManager.isRegistered(identifier: .visibilityToggle),
                searchHotkeyRegistered: hotkeyManager.isRegistered(identifier: .findIcon),
                hoverPollingActive: hoverRevealController.isPollingActive,
                autoRehideScheduled: rehideController.isScheduled,
                lastRehideReason: rehideController.lastReason?.rawValue,
                accessibilityPermissionStatus: accessibilityPermissionService.status,
                automationPaused: settingsStore.automationPaused
            )
        )
        refreshSearchAndSecondBarItemCounts()
    }

    func refreshSearchIndexItemCount() {
        liveStatus.updateSearchIndexItemCount(liveStatus.scannedMenuBarItems.count)
    }

    func refreshSecondBarItemCount() {
        liveStatus.updateSecondBarItemCount(menuBarItemCounts().secondBarItemCount)
    }

    func refreshSearchAndSecondBarItemCounts() {
        liveStatus.updateSearchAndSecondBarItemCounts(menuBarItemCounts())
    }

    private func menuBarItemCounts() -> LiveDiagnosticsMenuBarItemCounts {
        LiveDiagnosticsMenuBarItemCounts.counts(
            from: liveStatus.scannedMenuBarItems,
            includeHiddenInSecondBar: settingsStore.secondBarShowHiddenItems,
            includeAlwaysHiddenInSecondBar: settingsStore.secondBarShowAlwaysHiddenItems
        )
    }
}
