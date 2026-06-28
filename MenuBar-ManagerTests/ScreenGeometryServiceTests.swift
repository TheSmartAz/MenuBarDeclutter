import CoreGraphics
import Foundation
import Testing
@testable import MenuBar_Manager

@Suite("ScreenGeometryService")
@MainActor
struct ScreenGeometryServiceTests {
    @Test func minimumLengthHonouredWhenNoScreens() {
        let service = ScreenGeometryService(widthsProvider: { [] })

        let length = service.recommendedCollapsedSeparatorLength()

        // No screens -> widest width is treated as 1, so the minimum kick-in
        // (1200) is what we should observe.
        #expect(length == AppConstants.collapsedSeparatorMinimumLength)
    }

    @Test func collapsedLengthUsesWidestScreen() {
        let service = ScreenGeometryService(widthsProvider: { [800, 2560, 1440] })

        let length = service.recommendedCollapsedSeparatorLength()

        // 2560 * 2 = 5120, which is above the minimum and below the cap.
        #expect(length == 5120)
    }

    @Test func collapsedLengthRespectsMinimum() {
        let service = ScreenGeometryService(widthsProvider: { [400] })

        let length = service.recommendedCollapsedSeparatorLength()

        // 400 * 2 = 800 < 1200 -> floored to the minimum.
        #expect(length == AppConstants.collapsedSeparatorMinimumLength)
    }

    @Test func collapsedLengthRespectsCap() {
        let service = ScreenGeometryService(widthsProvider: { [8000] })

        let length = service.recommendedCollapsedSeparatorLength()

        // 8000 * 2 = 16000 -> capped at 10000.
        #expect(length == AppConstants.collapsedSeparatorMaximumLength)
    }

    @Test func pointInMenuBarBand() {
        let service = ScreenGeometryService(
            widthsProvider: { [2000] },
            menuBarBandsProvider: {
                [CGRect(x: 0, y: 900, width: 2000, height: 24)]
            }
        )

        #expect(service.isPointInAnyMenuBarBand(CGPoint(x: 0, y: 900)))
        #expect(service.isPointInAnyMenuBarBand(CGPoint(x: 1999, y: 923)))
        #expect(!service.isPointInAnyMenuBarBand(CGPoint(x: 1999, y: 925)))
        #expect(!service.isPointInAnyMenuBarBand(CGPoint(x: -1, y: 900)))
    }
}
