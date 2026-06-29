import AppKit
import Foundation

/// Main entry point for Phase 10 layout/capacity features.
///
/// Owns the Full Menu Bar Mode service, capacity service, suggestion service,
/// crowded reveal rescue service, spacer status item controller, and
/// menu bar spacing service. Receives references to shared services.
@MainActor
final class LayoutCoordinator {
    let settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    let appSupportPaths: AppSupportPaths

    let capacityService: LayoutCapacityService
    let suggestionService: LayoutSuggestionService
    let fullMenuBarModeService: FullMenuBarModeService
    let crowdedRevealRescueService: CrowdedRevealRescueService
    let spacerStore: SpacerItemStore
    let spacerFactory: SpacerStatusItemFactory
    let spacerController: SpacerStatusItemController
    let spacingService: MenuBarSpacingService

    private let screenGeometry: ScreenGeometryService
    private let hidingService: HidingService
    private let scanResultProvider: () -> MenuBarScanResult?

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        appSupportPaths: AppSupportPaths,
        screenGeometry: ScreenGeometryService,
        hidingService: HidingService,
        scanResultProvider: @escaping () -> MenuBarScanResult? = { nil },
        revealAll: @escaping () -> Void,
        restoreVisibility: @escaping (HidingVisibilityState) -> Void,
        suspendAutoRehide: @escaping () -> Void,
        resumeAutoRehide: @escaping () -> Void,
        showSpacerMarkers: @escaping (Bool) -> Void,
        openSecondBar: @escaping () -> Void,
        enterFullMenuBarMode: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appSupportPaths = appSupportPaths
        self.screenGeometry = screenGeometry
        self.hidingService = hidingService
        self.scanResultProvider = scanResultProvider

        self.capacityService = LayoutCapacityService()
        self.suggestionService = LayoutSuggestionService()

        let layoutDirectory = appSupportPaths.applicationSupportDirectory.appendingPathComponent("Layout", isDirectory: true)
        self.spacerStore = SpacerItemStore(
            directory: layoutDirectory,
            backupsDirectory: appSupportPaths.backupsDirectory,
            diagnosticsLogger: diagnosticsLogger
        )
        self.spacerFactory = SpacerStatusItemFactory(diagnosticsLogger: diagnosticsLogger)
        self.spacerController = SpacerStatusItemController(
            store: spacerStore,
            factory: spacerFactory,
            diagnosticsLogger: diagnosticsLogger
        )

        self.fullMenuBarModeService = FullMenuBarModeService(
            diagnosticsLogger: diagnosticsLogger,
            settingsStore: settingsStore,
            revealAll: revealAll,
            restoreVisibility: restoreVisibility,
            suspendAutoRehide: suspendAutoRehide,
            resumeAutoRehide: resumeAutoRehide,
            showSpacerMarkers: showSpacerMarkers,
            openSecondBar: openSecondBar
        )

        self.crowdedRevealRescueService = CrowdedRevealRescueService(
            diagnosticsLogger: diagnosticsLogger,
            settingsStore: settingsStore,
            openSecondBar: openSecondBar,
            enterFullMenuBarMode: enterFullMenuBarMode
        )

        self.spacingService = MenuBarSpacingService(
            settingsStore: settingsStore,
            diagnosticsLogger: diagnosticsLogger,
            commandRunner: DefaultMenuBarSpacingCommandRunner()
        )
    }

    /// Called at app startup to initialize Phase 10 features.
    func start() {
        guard settingsStore.layoutFeaturesEnabled else {
            diagnosticsLogger.log("Layout features disabled by user preference.", category: .layout)
            return
        }

        if settingsStore.spacerItemsEnabled {
            spacerController.installAll()
        }

        diagnosticsLogger.log("Layout coordinator started.", category: .layout)
    }

    /// Called at app shutdown.
    func stop() {
        spacerController.removeAllItems()
        if fullMenuBarModeService.isActive {
            fullMenuBarModeService.exit(reason: .safeMode)
        }
    }

    /// Generate the current capacity estimate for the primary screen.
    func currentCapacityEstimate() -> LayoutCapacityEstimate {
        let screenFrame = screenGeometry.screenFrame(intersecting: CGRect(x: 0, y: 0, width: 1, height: 1))
        let visibleFrame = screenFrame
        let scanResult = scanResultProvider()
        let threshold = settingsStore.crowdedRevealThresholdRatio

        return capacityService.estimate(
            screenID: "primary",
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            scanResult: scanResult,
            thresholdRatio: threshold,
            proModeEnabled: settingsStore.proModeEnabled
        )
    }

    /// Generate layout suggestions for the current state.
    func currentSuggestions() -> [LayoutSuggestion] {
        let estimate = currentCapacityEstimate()
        let settings = LayoutSettings(store: settingsStore)
        return suggestionService.generate(
            estimate: estimate,
            settings: settings,
            proModeEnabled: settingsStore.proModeEnabled,
            secondBarEnabled: settingsStore.secondBarEnabled,
            separatorLengthExtreme: settingsStore.expandedSeparatorLength > AppConstants.defaultExpandedSeparatorLength * 3,
            manyHiddenItems: estimate.knownHiddenItemCount > 5
        )
    }

    /// Enter Full Menu Bar Mode.
    func enterFullMenuBarMode() {
        fullMenuBarModeService.enter(previousVisibility: hidingService.visibilityState)
    }

    /// Exit Full Menu Bar Mode.
    func exitFullMenuBarMode() {
        fullMenuBarModeService.exit()
    }

    /// Safe Mode integration: disable all layout automation.
    func enterSafeMode() {
        fullMenuBarModeService.cancelAutoExit()
        if fullMenuBarModeService.isActive {
            fullMenuBarModeService.exit(reason: .safeMode)
        }
        crowdedRevealRescueService.resetState()
        spacerController.hideAllOptional()
        diagnosticsLogger.log("Layout coordinator entered Safe Mode.", level: .warning, category: .layout)
    }
}
