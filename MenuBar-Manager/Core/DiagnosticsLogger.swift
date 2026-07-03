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
    case dogfood
    case launchAtLogin
    case urlAutomation
    case privacy
    case layout

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
        case .dogfood:
            "Dogfood"
        case .launchAtLogin:
            "Launch at Login"
        case .urlAutomation:
            "URL Automation"
        case .layout:
            "Layout"
        default:
            rawValue.prefix(1).uppercased() + String(rawValue.dropFirst())
        }
    }

    static func inferred(from message: String) -> DiagnosticCategory {
        if message.containsAnyCaseInsensitive(in: ["safe mode"]) { return .safeMode }
        if message.containsAnyCaseInsensitive(in: ["dogfood"]) { return .dogfood }
        if message.containsAnyCaseInsensitive(in: ["launch at login", "smappservice"]) { return .launchAtLogin }
        if message.containsAnyCaseInsensitive(in: ["health"]) { return .health }
        if message.containsAnyCaseInsensitive(in: ["recover", "repair", "reset"]) { return .recovery }
        if message.containsAnyCaseInsensitive(in: ["trigger"]) { return .trigger }
        if message.containsAnyCaseInsensitive(in: ["profile"]) { return .profile }
        if message.containsAnyCaseInsensitive(in: ["url", "automation"]) { return .urlAutomation }
        if message.containsAnyCaseInsensitive(in: ["icon move", "moving", "drag"]) { return .iconMove }
        if message.containsAnyCaseInsensitive(in: ["second bar"]) { return .secondBar }
        if message.containsAnyCaseInsensitive(in: ["search", "find icon"]) { return .search }
        if message.containsAnyCaseInsensitive(in: ["scan", "ax ", "accessibility snapshot"]) { return .scan }
        if message.containsAnyCaseInsensitive(in: ["accessibility", "permission"]) { return .accessibility }
        if message.containsAnyCaseInsensitive(in: ["hotkey"]) { return .hotkey }
        if message.containsAnyCaseInsensitive(in: ["hover"]) { return .hover }
        if message.containsAnyCaseInsensitive(in: ["rehide"]) { return .rehide }
        if message.containsAnyCaseInsensitive(in: ["separator"]) { return .separator }
        if message.containsAnyCaseInsensitive(in: ["status item"]) { return .statusItem }
        if message.containsAnyCaseInsensitive(in: ["collapse", "expand", "visibility"]) {
            return .hiding
        }
        if message.containsAnyCaseInsensitive(in: ["quit", "stop", "terminated"]) {
            return .shutdown
        }
        if message.containsAnyCaseInsensitive(in: ["privacy", "screen recording", "network"]) {
            return .privacy
        }
        if message.containsAnyCaseInsensitive(in: ["layout", "spacer", "capacity", "spacing", "full menu bar", "crowded"]) {
            return .layout
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

    var accessibilitySummary: String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadataText = metadata
            .sorted { first, second in
                first.key.localizedStandardCompare(second.key) == .orderedAscending
            }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        let metadataSeparator = trimmedMessage.hasSuffix(".")
            || trimmedMessage.hasSuffix("!")
            || trimmedMessage.hasSuffix("?")
            ? " Metadata: "
            : ". Metadata: "
        let metadataSuffix = metadataText.isEmpty ? "" : "\(metadataSeparator)\(metadataText)"

        return "\(level.displayName), \(category.displayName). \(trimmedMessage)\(metadataSuffix)"
    }
}

private struct DiagnosticEventRingBuffer {
    private let capacity: Int
    private var storage: [DiagnosticEvent?]
    private var startIndex = 0
    private(set) var count = 0

    init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.storage = Array(repeating: nil, count: self.capacity)
    }

    var events: [DiagnosticEvent] {
        guard count > 0 else { return [] }

        return (0..<count).compactMap { offset in
            storage[(startIndex + offset) % capacity]
        }
    }

    mutating func append(_ event: DiagnosticEvent) {
        if count < capacity {
            storage[(startIndex + count) % capacity] = event
            count += 1
        } else {
            storage[startIndex] = event
            startIndex = (startIndex + 1) % capacity
        }
    }

    mutating func removeAll() {
        storage = Array(repeating: nil, count: capacity)
        startIndex = 0
        count = 0
    }
}

/// Hot-path-friendly case-insensitive substring check. Avoids the
/// `message.lowercased()` full-string allocation previously paid on every `log()`
/// call. `String.range(of:options:.caseInsensitive)` performs an in-place
/// case-folded comparison without materializing a new `String`.
private extension String {
    func containsAnyCaseInsensitive(in substrings: [String]) -> Bool {
        for substring in substrings {
            if range(of: substring, options: .caseInsensitive) != nil {
                return true
            }
        }
        return false
    }
}

@MainActor
@Observable
final class DiagnosticsLogger {
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let idProvider: () -> UUID

    private var eventBuffer: DiagnosticEventRingBuffer

    var events: [DiagnosticEvent] {
        eventBuffer.events
    }

    init(
        capacity: Int = AppConstants.diagnosticsRingBufferLimit,
        now: @escaping () -> Date = { Date() },
        idProvider: @escaping () -> UUID = { UUID() }
    ) {
        self.eventBuffer = DiagnosticEventRingBuffer(capacity: capacity)
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

        eventBuffer.append(event)

        #if DEBUG
        print("[\(AppConstants.displayName)] [\(event.category.displayName)] [\(level.rawValue.uppercased())] \(message)")
        #endif
    }

    func clear() {
        eventBuffer.removeAll()
    }

    func removeAll() {
        clear()
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
