import CoreGraphics
import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SecondBarPositioningService")
@MainActor
struct SecondBarPositioningServiceTests {
    @Test func panelStaysWithinVisibleScreenBounds() {
        let service = SecondBarPositioningService()
        let screen = makeScreen(visibleFrame: CGRect(x: 0, y: 0, width: 500, height: 300))

        let placement = service.placement(
            panelSize: CGSize(width: 320, height: 160),
            mode: .nearMouse,
            mouseLocation: CGPoint(x: 490, y: 290),
            lastPosition: nil,
            screens: [screen]
        )

        #expect(screen.visibleFrame.contains(placement.frame))
    }

    @Test func belowMenuBarPositionsPanelUnderVisibleFrameTop() {
        let service = SecondBarPositioningService()
        let screen = makeScreen(
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875)
        )

        let placement = service.placement(
            panelSize: CGSize(width: 600, height: 140),
            mode: .belowMenuBar,
            mouseLocation: CGPoint(x: 720, y: 880),
            lastPosition: nil,
            screens: [screen]
        )

        #expect(placement.frame.maxY <= screen.visibleFrame.maxY)
        #expect(placement.frame.maxY > screen.visibleFrame.maxY - 24)
    }

    @Test func fallsBackWhenScreensAreMissing() {
        let service = SecondBarPositioningService()

        let placement = service.placement(
            panelSize: CGSize(width: 400, height: 120),
            mode: .belowMenuBar,
            mouseLocation: .zero,
            lastPosition: nil,
            screens: []
        )

        #expect(placement.screenID == "fallback")
        #expect(placement.frame.width == 400)
    }

    @Test func lastPositionModeUsesDisplayContainingLastPosition() {
        let service = SecondBarPositioningService()
        let main = makeScreen(
            id: "main",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            visibleFrame: CGRect(x: 0, y: 0, width: 800, height: 575),
            isMain: true
        )
        let external = makeScreen(
            id: "external",
            frame: CGRect(x: 800, y: 0, width: 1200, height: 900),
            visibleFrame: CGRect(x: 800, y: 0, width: 1200, height: 875)
        )

        let placement = service.placement(
            panelSize: CGSize(width: 420, height: 160),
            mode: .lastPosition,
            mouseLocation: CGPoint(x: 200, y: 500),
            lastPosition: CGPoint(x: 1100, y: 700),
            screens: [main, external]
        )

        #expect(placement.screenID == "external")
        #expect(external.visibleFrame.contains(placement.frame.origin))
    }

    @Test func invalidLastPositionFallsBackToMouseDisplay() {
        let service = SecondBarPositioningService()
        let main = makeScreen(
            id: "main",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            visibleFrame: CGRect(x: 0, y: 0, width: 800, height: 575),
            isMain: true
        )
        let external = makeScreen(
            id: "external",
            frame: CGRect(x: 800, y: 0, width: 1200, height: 900),
            visibleFrame: CGRect(x: 800, y: 0, width: 1200, height: 875)
        )

        let placement = service.placement(
            panelSize: CGSize(width: 420, height: 160),
            mode: .lastPosition,
            mouseLocation: CGPoint(x: 1200, y: 500),
            lastPosition: CGPoint(x: -4000, y: -4000),
            screens: [main, external]
        )

        #expect(placement.screenID == "external")
        #expect(external.visibleFrame.contains(placement.frame.origin))
    }

    @Test func notchAvoidanceMovesPanelOutOfModeledNotch() {
        let service = SecondBarPositioningService()
        let notch = CGRect(x: 600, y: 780, width: 240, height: 120)
        let screen = makeScreen(
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            notchAvoidanceRect: notch
        )

        let placement = service.placement(
            panelSize: CGSize(width: 300, height: 80),
            mode: .belowMenuBar,
            mouseLocation: CGPoint(x: 720, y: 880),
            lastPosition: nil,
            screens: [screen]
        )

        #expect(placement.avoidedNotch)
        #expect(!placement.frame.intersects(notch))
    }

    @Test func screenSnapshotCacheReusesSnapshotsUntilInvalidated() {
        var providerCallCount = 0
        var screenWidth: CGFloat = 800
        let cache = SecondBarScreenSnapshotCache {
            providerCallCount += 1
            return [
                makeScreen(
                    frame: CGRect(x: 0, y: 0, width: screenWidth, height: 600),
                    visibleFrame: CGRect(x: 0, y: 0, width: screenWidth, height: 575)
                )
            ]
        }

        let firstSnapshots = cache.snapshots()
        screenWidth = 1200
        let cachedSnapshots = cache.snapshots()

        #expect(providerCallCount == 1)
        #expect(cachedSnapshots == firstSnapshots)

        cache.invalidate()
        let refreshedSnapshots = cache.snapshots()

        #expect(providerCallCount == 2)
        #expect(refreshedSnapshots != firstSnapshots)
        #expect(refreshedSnapshots.first?.frame.width == 1200)
    }

    private func makeScreen(
        id: String = "test",
        frame: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
        visibleFrame: CGRect = CGRect(x: 0, y: 0, width: 800, height: 575),
        isMain: Bool = true,
        notchAvoidanceRect: CGRect? = nil
    ) -> SecondBarScreenSnapshot {
        SecondBarScreenSnapshot(
            id: id,
            frame: frame,
            visibleFrame: visibleFrame,
            isMain: isMain,
            notchAvoidanceRect: notchAvoidanceRect
        )
    }
}
