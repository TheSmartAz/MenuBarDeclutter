import Foundation
import Testing
@testable import MenuBar_Manager

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
}
