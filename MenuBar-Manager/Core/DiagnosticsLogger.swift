import Foundation
import Observation

enum DiagnosticLevel: String, CaseIterable, Identifiable, Sendable {
    case debug
    case info
    case warning
    case error

    var id: String { rawValue }
}

struct DiagnosticEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: DiagnosticLevel
    let message: String
}

@Observable
final class DiagnosticsLogger {
    @ObservationIgnored private let capacity: Int
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let idProvider: () -> UUID

    private(set) var events: [DiagnosticEvent] = []

    init(
        capacity: Int = AppConstants.diagnosticsRingBufferLimit,
        now: @escaping () -> Date = { Date() },
        idProvider: @escaping () -> UUID = { UUID() }
    ) {
        self.capacity = max(1, capacity)
        self.now = now
        self.idProvider = idProvider
    }

    func log(_ message: String, level: DiagnosticLevel = .info) {
        let event = DiagnosticEvent(
            id: idProvider(),
            timestamp: now(),
            level: level,
            message: message
        )

        events.append(event)

        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }

        #if DEBUG
        print("[\(AppConstants.displayName)] [\(level.rawValue.uppercased())] \(message)")
        #endif
    }

    func removeAll() {
        events.removeAll()
    }
}
