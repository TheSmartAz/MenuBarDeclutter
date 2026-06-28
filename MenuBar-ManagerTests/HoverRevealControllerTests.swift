import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HoverRevealController")
@MainActor
struct HoverRevealControllerTests {
    private func makeController(
        screenGeometry: ScreenGeometryService = ScreenGeometryService(widthsProvider: { [2560] })
    ) -> HoverRevealController {
        let suiteName = "HoverRevealControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = SettingsStore(defaults: defaults)
        let logger = DiagnosticsLogger()
        return HoverRevealController(
            settingsStore: store,
            screenGeometry: screenGeometry,
            diagnosticsLogger: logger
        )
    }

    @Test func revealsOnEnterWhenCollapsed() {
        let controller = makeController()
        var decision = controller.processMouseLocation(isInMenuBarBand: true, isCollapsed: true, autoRehideEnabled: true)
        #expect(decision.shouldReveal == true)
        #expect(decision.shouldScheduleRehide == false)

        // Still hovering; no new reveal.
        decision = controller.processMouseLocation(isInMenuBarBand: true, isCollapsed: true, autoRehideEnabled: true)
        #expect(decision.shouldReveal == false)
    }

    @Test func schedulesRehideWhenLeaving() {
        let controller = makeController()
        _ = controller.processMouseLocation(isInMenuBarBand: true, isCollapsed: true, autoRehideEnabled: true)
        let decision = controller.processMouseLocation(isInMenuBarBand: false, isCollapsed: false, autoRehideEnabled: true)
        #expect(decision.shouldScheduleRehide == true)
    }

    @Test func noRehideScheduledWhenAutoRehideDisabled() {
        let controller = makeController()
        _ = controller.processMouseLocation(isInMenuBarBand: true, isCollapsed: true, autoRehideEnabled: true)
        let decision = controller.processMouseLocation(isInMenuBarBand: false, isCollapsed: false, autoRehideEnabled: false)
        #expect(decision.shouldScheduleRehide == false)
    }

    @Test func noRevealWhenAlreadyExpanded() {
        let controller = makeController()
        let decision = controller.processMouseLocation(isInMenuBarBand: true, isCollapsed: false, autoRehideEnabled: true)
        #expect(decision.shouldReveal == false)
    }

    @Test func noRevealWhenLeavingBandWithoutPriorEnter() {
        let controller = makeController()
        let decision = controller.processMouseLocation(isInMenuBarBand: false, isCollapsed: true, autoRehideEnabled: true)
        #expect(decision.shouldReveal == false)
        #expect(decision.shouldScheduleRehide == false)
    }

    @Test func tickSkipsGeometryWhenExpandedAndNotPreviouslyHovering() {
        var geometryCalls = 0
        var mouseCalls = 0
        let geometry = ScreenGeometryService(
            widthsProvider: { [2560] },
            menuBarBandsProvider: {
                geometryCalls += 1
                return [CGRect(x: 0, y: 900, width: 2000, height: 24)]
            }
        )
        let controller = makeController(screenGeometry: geometry)
        controller.isCollapsedProvider = { false }
        controller.mouseLocationProvider = {
            mouseCalls += 1
            return CGPoint(x: 10, y: 910)
        }

        controller.tick()

        #expect(geometryCalls == 0)
        #expect(mouseCalls == 0)
    }
}
