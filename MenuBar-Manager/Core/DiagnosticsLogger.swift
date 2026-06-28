import Foundation
import Observation

enum DiagnosticLevel: String, CaseIterable, Identifiable, Sendable {
    case debug
    case info
    case warning
    case error

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

enum DiagnosticCategory: String, CaseIterable, Identifiable, Sendable {
    case startup
    case shutdown
    case statusItem
    case separator
    case hiding
    case rehide
    case hover
    case hotkey
    case accessibility
    case scan
    case search
    case secondBar
    case iconMove
    case profile
    case trigger
    case health
    case recovery
    case safeMode
    case launchAtLogin
    case urlAutomation
    case privacy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .statusItem:
            "Status Item"
        case .secondBar:
            "Second Bar"
        case .iconMove:
            "Icon Move"
        case .safeMode:
            "Safe Mode"
        case .launchAtLogin:
            "Launch at Login"
        case .urlAutomation:
            "URL Automation"
        default:
            rawValue.prefix(1).uppercased() + String(rawValue.dropFirst())
        }
    }

    static func inferred(from message: String) -> DiagnosticCategory {
        let lowercased = message.lowercased()
        if lowercased.contains("safe mode") { return .safeMode }
        if lowercased.contains("launch at login") || lowercased.contains("smappservice") { return .launchAtLogin }
        if lowercased.contains("health") { return .health }
        if lowercased.contains("recover") || lowercased.contains("repair") || lowercased.contains("reset") { return .recovery }
        if lowercased.contains("trigger") { return .trigger }
        if lowercased.contains("profile") { return .profile }
        if lowercased.contains("url") || lowercased.contains("automation") { return .urlAutomation }
        if lowercased.contains("icon move") || lowercased.contains("moving") || lowercased.contains("drag") { return .iconMove }
        if lowercased.contains("second bar") { return .secondBar }
        if lowercased.contains("search") || lowercased.contains("find icon") { return .search }
        if lowercased.contains("scan") || lowercased.contains("ax ") || lowercased.contains("accessibility snapshot") { return .scan }
        if lowercased.contains("accessibility") || lowercased.contains("permission") { return .accessibility }
        if lowercased.contains("hotkey") { return .hotkey }
        if lowercased.contains("hover") { return .hover }
        if lowercased.contains("rehide") { return .rehide }
        if lowercased.contains("separator") { return .separator }
        if lowercased.contains("status item") { return .statusItem }
        if lowercased.contains("collapse") || lowercased.contains("expand") || lowercased.contains("visibility") {
            return .hiding
        }
        if lowercased.contains("quit") || lowercased.contains("stop") || lowercased.contains("terminated") {
            return .shutdown
        }
        if lowercased.contains("privacy") || lowercased.contains("screen recording") || lowercased.contains("network") {
            return .privacy
        }
        return .startup
    }
}

struct DiagnosticEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let category: DiagnosticCategory
    let level: DiagnosticLevel
    let message: String
    let metadata: [String: String]

    var formattedSummary: String {
        let metadataText = metadata.isEmpty ? "" : " \(metadata)"
        return "[\(level.rawValue.uppercased())] [\(category.displayName)] \(message)\(metadataText)"
    }
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

    func log(
        _ message: String,
        level: DiagnosticLevel = .info,
        category: DiagnosticCategory? = nil,
        metadata: [String: String] = [:]
    ) {
        let event = DiagnosticEvent(
            id: idProvider(),
            timestamp: now(),
            category: category ?? DiagnosticCategory.inferred(from: message),
            level: level,
            message: message,
            metadata: Self.sanitized(metadata)
        )

        events.append(event)

        if events.count > capacity {
            events.removeFirst(events.count - capacity)
        }

        #if DEBUG
        print("[\(AppConstants.displayName)] [\(event.category.displayName)] [\(level.rawValue.uppercased())] \(message)")
        #endif
    }

    func removeAll() {
        events.removeAll()
    }

    private static func sanitized(_ metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            let key = pair.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return }
            let value = pair.value
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            result[key] = value
        }
    }
}
