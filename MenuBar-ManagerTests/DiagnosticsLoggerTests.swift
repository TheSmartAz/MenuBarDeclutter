import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("DiagnosticsLogger")
@MainActor
struct DiagnosticsLoggerTests {
    @Test func ringBufferRetainsLatestEvents() {
        let logger = DiagnosticsLogger(
            capacity: 3,
            now: { Date(timeIntervalSince1970: 0) },
            idProvider: { UUID(uuidString: "00000000-0000-0000-0000-000000000001")! }
        )

        for index in 0..<5 {
            logger.log("event \(index)")
        }

        #expect(logger.events.map(\.message) == ["event 2", "event 3", "event 4"])
    }

    @Test func capacityIsAtLeastOne() {
        let logger = DiagnosticsLogger(capacity: 0)

        logger.log("first")
        logger.log("second")

        #expect(logger.events.map(\.message) == ["second"])
    }

    @Test func capacityOneRetainsOnlyMostRecentEvent() {
        let logger = DiagnosticsLogger(capacity: 1)

        logger.log("first")
        logger.log("second")
        logger.log("third")

        #expect(logger.events.map(\.message) == ["third"])
    }

    @Test func clearEmptiesLoggedEvents() {
        let logger = DiagnosticsLogger(capacity: 2)

        logger.log("first")
        logger.log("second")
        logger.clear()

        #expect(logger.events.isEmpty)
    }

    @Test func structuredEventsKeepCategorySeverityAndMetadata() {
        let logger = DiagnosticsLogger(
            now: { Date(timeIntervalSince1970: 1) },
            idProvider: { UUID(uuidString: "00000000-0000-0000-0000-000000000002")! }
        )

        logger.log(
            "Automation paused for QA.",
            level: .warning,
            category: .trigger,
            metadata: ["source": "test\ncase"]
        )

        let event = logger.events[0]
        #expect(event.level == .warning)
        #expect(event.category == .trigger)
        #expect(event.metadata["source"] == "test case")
        #expect(event.formattedSummary.contains("Automation paused for QA."))
    }

    @Test func accessibilitySummaryUsesStableMetadataOrder() {
        let event = DiagnosticEvent(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            timestamp: Date(timeIntervalSince1970: 2),
            category: .scan,
            level: .warning,
            message: "Scan paused.",
            metadata: [
                "window": "Settings",
                "app": "MenuBarDeclutter"
            ]
        )

        #expect(
            event.accessibilitySummary ==
                "Warning, Scan. Scan paused. Metadata: app: MenuBarDeclutter, window: Settings"
        )
    }
}
