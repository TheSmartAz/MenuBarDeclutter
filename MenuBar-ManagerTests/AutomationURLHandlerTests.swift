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
        #expect(handler.handle(url: try #require(URL(string: "menubardeclutter://second-bar"))))

        #expect(recorder.commands == ["expand", "collapse", "revealAll", "secondBar"])
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
        #expect(recorder.logged("Automation URL rejected: profile not found."))
        #expect(recorder.logged("Automation URL rejected: profile command missing profile name."))
    }

    @Test func rejectsCommandsWhenAutomationPaused() throws {
        let recorder = AutomationRecorder()
        recorder.automationEnabled = false
        let handler = recorder.makeHandler()

        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://expand"))))

        #expect(recorder.commands.isEmpty)
        #expect(recorder.logged("Automation URL rejected: automation paused."))
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

    let logger = DiagnosticsLogger()
    var automationEnabled = true
    var commands: [String] = []
    var profileNames: [String] = []
    private var currentDate = Date(timeIntervalSinceReferenceDate: 0)

    init(profilesThatApply: Set<String> = []) {
        self.profilesThatApply = profilesThatApply
    }

    func makeHandler(minimumCommandInterval: TimeInterval = 0.5) -> AutomationURLHandler {
        AutomationURLHandler(
            diagnosticsLogger: logger,
            expand: { [self] in commands.append("expand") },
            collapse: { [self] in commands.append("collapse") },
            revealAll: { [self] in commands.append("revealAll") },
            showSecondBar: { [self] in commands.append("secondBar") },
            applyProfileNamed: { [self] name in
                profileNames.append(name)
                return profilesThatApply.contains(name)
            },
            isAutomationEnabled: { [self] in automationEnabled },
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
}
