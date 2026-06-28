import Foundation
import Testing
@testable import MenuBar_Manager

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

    @Test func rejectsUnknownCommandsAndMissingProfiles() throws {
        let recorder = AutomationRecorder()
        let handler = recorder.makeHandler()

        #expect(!handler.handle(url: try #require(URL(string: "https://example.com/expand"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://unknown"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://profile/Missing"))))
        #expect(!handler.handle(url: try #require(URL(string: "menubardeclutter://profile"))))

        #expect(recorder.commands.isEmpty)
        #expect(recorder.profileNames == ["Missing"])
    }
}

@MainActor
private final class AutomationRecorder {
    private let profilesThatApply: Set<String>

    var commands: [String] = []
    var profileNames: [String] = []

    init(profilesThatApply: Set<String> = []) {
        self.profilesThatApply = profilesThatApply
    }

    func makeHandler() -> AutomationURLHandler {
        AutomationURLHandler(
            diagnosticsLogger: DiagnosticsLogger(),
            expand: { [self] in commands.append("expand") },
            collapse: { [self] in commands.append("collapse") },
            revealAll: { [self] in commands.append("revealAll") },
            showSecondBar: { [self] in commands.append("secondBar") },
            applyProfileNamed: { [self] name in
                profileNames.append(name)
                return profilesThatApply.contains(name)
            }
        )
    }
}
