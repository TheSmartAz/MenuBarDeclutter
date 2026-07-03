import Foundation

enum TriggerRule: Codable, Equatable, Sendable {
    case externalDisplayConnected(minimumDisplayCount: Int)
    case appLaunched(bundleIdentifier: String)
    case frontmostApp(bundleIdentifier: String)
    case batteryLow(thresholdPercent: Int)
    case timeOfDay(hour: Int, minute: Int)
    case focusModePlaceholder
    case wifiSSID(String)

    var displayName: String {
        switch self {
        case .externalDisplayConnected(let count):
            "Display count at least \(count)"
        case .appLaunched(let bundleIdentifier):
            "App launched: \(bundleIdentifier)"
        case .frontmostApp(let bundleIdentifier):
            "Frontmost app: \(bundleIdentifier)"
        case .batteryLow(let threshold):
            "Battery below \(threshold)%"
        case .timeOfDay(let hour, let minute):
            "Time \(String(format: "%02d:%02d", hour, minute))"
        case .focusModePlaceholder:
            "Focus mode placeholder"
        case .wifiSSID(let ssid):
            "Wi-Fi: \(ssid)"
        }
    }

    var isSupportedByCurrentRuntime: Bool {
        switch self {
        case .externalDisplayConnected, .appLaunched, .frontmostApp, .batteryLow, .timeOfDay:
            true
        case .focusModePlaceholder, .wifiSSID:
            false
        }
    }

    var unsupportedRuntimeReason: String? {
        switch self {
        case .externalDisplayConnected, .appLaunched, .frontmostApp, .batteryLow, .timeOfDay:
            nil
        case .focusModePlaceholder:
            "Focus trigger provider is not available in this build."
        case .wifiSSID:
            "Wi-Fi trigger provider is not available without adding new permissions."
        }
    }
}

struct TriggerModel: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var profileID: ProfileModel.ID
    var isEnabled: Bool
    var rule: TriggerRule
    var debounceSeconds: TimeInterval
    var lastFiredAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        profileID: ProfileModel.ID,
        isEnabled: Bool = true,
        rule: TriggerRule,
        debounceSeconds: TimeInterval = 60,
        lastFiredAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.profileID = profileID
        self.isEnabled = isEnabled
        self.rule = rule
        self.debounceSeconds = debounceSeconds
        self.lastFiredAt = lastFiredAt
    }
}

struct TriggerEvaluationContext: Equatable, Sendable {
    var displayCount: Int
    var runningBundleIdentifiers: Set<String>
    var frontmostBundleIdentifier: String?
    var batteryPercent: Int?
    var dateComponents: DateComponents
    var focusModeActive: Bool?
    var wifiSSID: String?

    init(
        displayCount: Int = 1,
        runningBundleIdentifiers: Set<String> = [],
        frontmostBundleIdentifier: String? = nil,
        batteryPercent: Int? = nil,
        dateComponents: DateComponents = Calendar.current.dateComponents([.hour, .minute], from: Date()),
        focusModeActive: Bool? = nil,
        wifiSSID: String? = nil
    ) {
        self.displayCount = displayCount
        self.runningBundleIdentifiers = runningBundleIdentifiers
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.batteryPercent = batteryPercent
        self.dateComponents = dateComponents
        self.focusModeActive = focusModeActive
        self.wifiSSID = wifiSSID
    }
}
