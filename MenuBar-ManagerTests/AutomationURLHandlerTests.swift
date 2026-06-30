import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("AutomationURLHandler")
@MainActor
struct AutomationURLHandlerTests {
    @Test func dispatchesBasicCommands() throws {
        let recorder = AutomationRecorder()
        let handler = recorder.makeHandler()

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))
        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://collapse"))))
        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://reveal-all"))))

        #expect(recorder.commands == ["expand", "collapse", "revealAll"])
    }

    @Test func secondBarCommandUsesSharedProGate() throws {
        let recorder = AutomationRecorder()
        let handler = recorder.makeHandler()

        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://second-bar"))))

        #expect(recorder.commands.isEmpty)
        #expect(recorder.loggedCommandReason("proModeDisabled"))
    }

    @Test func appliesProfileByDecodedName() throws {
        let recorder = AutomationRecorder(profilesThatApply: ["Work Mode"])
        let handler = recorder.makeHandler()

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://profile/Work%20Mode"))))

        #expect(recorder.profileNames == ["Work Mode"])
    }

    @Test func appliesProfileWithoutDoubleDecodingName() throws {
        let recorder = AutomationRecorder(profilesThatApply: ["Work%20Mode"])
        let handler = recorder.makeHandler()

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://profile/Work%2520Mode"))))

        #expect(recorder.profileNames == ["Work%20Mode"])
    }

    @Test func opensGroupPanelByUUID() throws {
        let groupID = UUID()
        let recorder = AutomationRecorder(groupsThatOpen: [groupID])
        let handler = recorder.makeHandler()

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://group/\(groupID.uuidString)"))))

        #expect(recorder.groupPanelIDs == [groupID])
    }

    @Test func revealGroupUsesSharedProGate() throws {
        let groupID = UUID()
        let recorder = AutomationRecorder(groupsThatReveal: [groupID])
        let handler = recorder.makeHandler()

        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://reveal-group/\(groupID.uuidString)"))))

        #expect(recorder.revealGroupIDs.isEmpty)
        #expect(recorder.loggedCommandReason("proModeDisabled"))
    }

    @Test func revealGroupByUUIDSucceedsWhenGatesAreOpen() throws {
        let groupID = UUID()
        let recorder = AutomationRecorder(groupsThatReveal: [groupID])
        recorder.proModeEnabled = true
        recorder.accessibilityDiscoveryEnabled = true
        let handler = recorder.makeHandler()

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://reveal-group/\(groupID.uuidString)"))))

        #expect(recorder.revealGroupIDs == [groupID])
    }

    @Test func rejectsUnknownCommandsAndMissingProfiles() throws {
        let recorder = AutomationRecorder()
        let handler = recorder.makeHandler(minimumCommandInterval: 0)

        #expect(!handler.handle(url: try #require(URL(string: "https://example.com/expand"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://unknown"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://profile/Missing"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://profile"))))

        #expect(recorder.commands.isEmpty)
        #expect(recorder.profileNames == ["Missing"])
        #expect(recorder.logged("Automation URL rejected: unsupported scheme."))
        #expect(recorder.logged("Automation URL rejected: unknown command."))
        #expect(recorder.loggedCommandReason("profileUnavailable"))
        #expect(recorder.logged("Automation URL rejected: profile command missing profile name."))
    }

    @Test func rejectsCommandsWhenAutomationPaused() throws {
        let recorder = AutomationRecorder()
        recorder.automationEnabled = false
        let handler = recorder.makeHandler()

        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))

        #expect(recorder.commands.isEmpty)
        #expect(recorder.loggedCommandReason("automationPaused"))
    }

    @Test func rateLimitsRepeatedCommandsPerCommand() throws {
        let recorder = AutomationRecorder()
        let handler = recorder.makeHandler(minimumCommandInterval: 1)

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))
        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://collapse"))))

        recorder.advance(by: 1)

        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))

        #expect(recorder.commands == ["expand", "collapse", "expand"])
        #expect(recorder.logged("Automation URL rejected: command rate limited."))
    }
}

@MainActor
private final class AutomationRecorder {
    private let profilesThatApply: Set<String>
    private let groupsThatOpen: Set<UUID>
    private let groupsThatReveal: Set<UUID>

    let store: SettingsStore
    let logger = DiagnosticsLogger()
    var automationEnabled = true
    var proModeEnabled = false
    var accessibilityDiscoveryEnabled = false
    var commands: [String] = []
    var profileNames: [String] = []
    var groupPanelIDs: [UUID] = []
    var revealGroupIDs: [UUID] = []
    private var currentDate = Date(timeIntervalSinceReferenceDate: 0)

    init(
        profilesThatApply: Set<String> = [],
        groupsThatOpen: Set<UUID> = [],
        groupsThatReveal: Set<UUID> = []
    ) {
        self.profilesThatApply = profilesThatApply
        self.groupsThatOpen = groupsThatOpen
        self.groupsThatReveal = groupsThatReveal
        let suiteName = "AutomationURLHandlerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        store = SettingsStore(defaults: defaults)
    }

    func makeHandler(minimumCommandInterval: TimeInterval = 0.5) -> AutomationURLHandler {
        store.automationPaused = !automationEnabled
        store.proModeEnabled = proModeEnabled
        store.accessibilityDiscoveryEnabled = accessibilityDiscoveryEnabled
        store.appIntentsCanApplyProfiles = true
        var handlers = MenuBarCommandHandlers()
        handlers.expand = { [self] in commands.append("expand") }
        handlers.collapse = { [self] in commands.append("collapse") }
        handlers.revealAll = { [self] in commands.append("revealAll") }
        handlers.showSecondBar = { [self] in commands.append("secondBar") }
        handlers.showGroupPanel = { [self] id in
            groupPanelIDs.append(id)
            return groupsThatOpen.contains(id)
        }
        handlers.revealGroup = { [self] id in
            revealGroupIDs.append(id)
            return groupsThatReveal.contains(id)
        }
        handlers.applyProfileNamed = { [self] name in
            profileNames.append(name)
            return profilesThatApply.contains(name)
        }
        let router = MenuBarCommandRouter(
            settingsStore: store,
            diagnosticsLogger: logger,
            accessibilityStatus: { .granted },
            handlers: handlers
        )

        return AutomationURLHandler(
            diagnosticsLogger: logger,
            routeCommand: { command in router.route(command) },
            now: { [self] in currentDate },
            minimumCommandInterval: minimumCommandInterval
        )
    }

    func advance(by interval: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(interval)
    }

    func logged(_ message: String) -> Bool {
        logger.events.contains { $0.message == message }
    }

    func loggedCommandReason(_ reason: String) -> Bool {
        logger.events.contains { event in
            event.metadata["reason"] == reason
        }
    }
}
