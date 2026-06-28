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
        liveStatus.visibilityState = hidingService.visibilityState
        liveStatus.primarySeparatorLength = primarySeparatorController.currentLength
        liveStatus.alwaysHiddenSeparatorLength = alwaysHiddenSeparatorController.currentLength
        liveStatus.alwaysHiddenSeparatorInstalled = alwaysHiddenSeparatorController.statusItem != nil
        liveStatus.hotkeyRegistered = hotkeyManager.isRegistered(identifier: .visibilityToggle)
        liveStatus.searchHotkeyRegistered = hotkeyManager.isRegistered(identifier: .findIcon)
        liveStatus.hoverPollingActive = hoverRevealController.isPollingActive
        liveStatus.autoRehideScheduled = rehideController.isScheduled
        liveStatus.lastRehideReason = rehideController.lastReason?.rawValue
        liveStatus.accessibilityPermissionStatus = accessibilityPermissionService.status
        refreshSearchAndSecondBarItemCounts()
    }

    func refreshSearchIndexItemCount() {
        liveStatus.searchIndexItemCount = liveStatus.scannedMenuBarItems.count
    }

    func refreshSecondBarItemCount() {
        liveStatus.secondBarItemCount = liveStatus.scannedMenuBarItems.filter {
            ($0.zone == .hidden && settingsStore.secondBarShowHiddenItems)
                || ($0.zone == .alwaysHidden && settingsStore.secondBarShowAlwaysHiddenItems)
        }.count
    }

    func refreshSearchAndSecondBarItemCounts() {
        refreshSearchIndexItemCount()
        refreshSecondBarItemCount()
    }
}
