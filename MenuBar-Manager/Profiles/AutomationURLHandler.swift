import AppKit
import Foundation

@MainActor
final class AutomationURLHandler {
    private enum Command: Hashable {
        case expand
        case collapse
        case revealAll
        case secondBar
        case groupPanel
        case revealGroup
        case profile
        case fullMenuBar
        case exitFullMenuBar
        case layoutSuggestions

        var logName: String {
            switch self {
            case .expand:
                "expand"
            case .collapse:
                "collapse"
            case .revealAll:
                "reveal-all"
            case .secondBar:
                "second-bar"
            case .groupPanel:
                "group"
            case .revealGroup:
                "reveal-group"
            case .profile:
                "profile"
            case .fullMenuBar:
                "full-menu-bar"
            case .exitFullMenuBar:
                "exit-full-menu-bar"
            case .layoutSuggestions:
                "layout-suggestions"
            }
        }

        init?(host: String) {
            switch host {
            case "expand":
                self = .expand
            case "collapse":
                self = .collapse
            case "reveal-all", "revealAll":
                self = .revealAll
            case "second-bar", "show-second-bar":
                self = .secondBar
            case "group", "open-group", "show-group-panel":
                self = .groupPanel
            case "reveal-group":
                self = .revealGroup
            case "profile":
                self = .profile
            case "full-menu-bar":
                self = .fullMenuBar
            case "exit-full-menu-bar":
                self = .exitFullMenuBar
            case "layout-suggestions":
                self = .layoutSuggestions
            default:
                return nil
            }
        }
    }

    private static let scheme = "menubardeclutter"
    private static let defaultMinimumCommandInterval: TimeInterval = 0.5

    private let diagnosticsLogger: DiagnosticsLogger
    private let routeCommand: (MenuBarCommand) -> MenuBarCommandResult
    private let now: () -> Date
    private let minimumCommandInterval: TimeInterval

    private var lastAcceptedAtByCommand: [Command: Date] = [:]
    private var isInstalled = false

    init(
        diagnosticsLogger: DiagnosticsLogger,
        routeCommand: @escaping (MenuBarCommand) -> MenuBarCommandResult,
        now: @escaping () -> Date = { Date() },
        minimumCommandInterval: TimeInterval = AutomationURLHandler.defaultMinimumCommandInterval
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.routeCommand = routeCommand
        self.now = now
        self.minimumCommandInterval = max(0, minimumCommandInterval)
    }

    func install() {
        guard !isInstalled else {
            diagnosticsLogger.log(
                "Automation URL handler already installed.",
                level: .debug,
                category: .urlAutomation
            )
            return
        }

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        isInstalled = true

        diagnosticsLogger.log(
            "Automation URL handler installed.",
            level: .debug,
            category: .urlAutomation
        )
    }

    func uninstall() {
        guard isInstalled else { return }
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        isInstalled = false
        lastAcceptedAtByCommand.removeAll()
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        process(url: url, eventMetadata: [:])
    }

    @discardableResult
    private func process(url: URL, eventMetadata: [String: String]) -> Bool {
        guard url.scheme?.lowercased() == Self.scheme else {
            logRejection(
                "unsupported scheme",
                metadata: metadata(eventMetadata, adding: [
                    "scheme": url.scheme ?? "missing"
                ])
            )
            return false
        }

        let host = url.host(percentEncoded: false) ?? ""
        guard let command = Command(host: host) else {
            logRejection(
                "unknown command",
                metadata: metadata(eventMetadata, adding: [
                    "command": host.isEmpty ? "missing" : host
                ])
            )
            return false
        }

        guard accept(command: command, eventMetadata: eventMetadata) else {
            return false
        }

        guard let routedCommand = routedCommand(for: command, url: url, eventMetadata: eventMetadata) else {
            return false
        }

        return routeCommand(routedCommand).didRun
    }

    private func accept(command: Command, eventMetadata: [String: String]) -> Bool {
        guard minimumCommandInterval > 0 else { return true }

        let currentDate = now()
        if let lastAcceptedAt = lastAcceptedAtByCommand[command],
           currentDate.timeIntervalSince(lastAcceptedAt) < minimumCommandInterval {
            logRejection(
                "command rate limited",
                metadata: metadata(eventMetadata, adding: [
                    "command": command.logName,
                    "minimumIntervalSeconds": String(format: "%.2f", minimumCommandInterval)
                ])
            )
            return false
        }

        lastAcceptedAtByCommand[command] = currentDate
        return true
    }

    private func profileName(from url: URL) -> String? {
        url.pathComponents.first { $0 != "/" }
    }

    private func groupID(from url: URL) -> UUID? {
        guard let rawValue = url.pathComponents.first(where: { $0 != "/" }) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }

    private func routedCommand(
        for command: Command,
        url: URL,
        eventMetadata: [String: String]
    ) -> MenuBarCommand? {
        switch command {
        case .expand:
            return MenuBarCommand(action: .expand, target: .globalVisibility, source: .urlAutomation)
        case .collapse:
            return MenuBarCommand(action: .collapse, target: .globalVisibility, source: .urlAutomation)
        case .revealAll:
            return MenuBarCommand(action: .revealAll, target: .globalVisibility, source: .urlAutomation)
        case .secondBar:
            return MenuBarCommand(action: .showSecondBar, target: .secondBar, source: .urlAutomation)
        case .groupPanel:
            guard let id = groupID(from: url) else {
                logRejection(
                    "group command missing group id",
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName
                    ])
                )
                return nil
            }
            return MenuBarCommand(action: .showGroupPanel, target: .group(id), source: .urlAutomation)
        case .revealGroup:
            guard let id = groupID(from: url) else {
                logRejection(
                    "group command missing group id",
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName
                    ])
                )
                return nil
            }
            return MenuBarCommand(action: .revealGroup, target: .group(id), source: .urlAutomation)
        case .profile:
            guard let name = profileName(from: url), !name.isEmpty else {
                logRejection(
                    "profile command missing profile name",
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName
                    ])
                )
                return nil
            }
            return MenuBarCommand(action: .applyProfile, target: .profileName(name), source: .urlAutomation)
        case .fullMenuBar:
            return MenuBarCommand(action: .enterFullMenuBarMode, target: .fullMenuBarMode, source: .urlAutomation)
        case .exitFullMenuBar:
            return MenuBarCommand(action: .exitFullMenuBarMode, target: .fullMenuBarMode, source: .urlAutomation)
        case .layoutSuggestions:
            return MenuBarCommand(action: .showLayoutSuggestions, target: .layoutSuggestions, source: .urlAutomation)
        }
    }

    private func logRejection(
        _ reason: String,
        metadata: [String: String],
        level: DiagnosticLevel = .warning
    ) {
        diagnosticsLogger.log(
            "Automation URL rejected: \(reason).",
            level: level,
            category: .urlAutomation,
            metadata: metadata
        )
    }

    private func metadata(
        _ eventMetadata: [String: String],
        adding values: [String: String]
    ) -> [String: String] {
        eventMetadata.merging(values) { _, new in new }
    }

    @objc private func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        let eventMetadata = senderMetadata(from: event)
        guard let rawURL = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: rawURL) else {
            logRejection("event missing URL", metadata: eventMetadata)
            return
        }

        _ = process(url: url, eventMetadata: eventMetadata)
    }

    private func senderMetadata(from event: NSAppleEventDescriptor) -> [String: String] {
        guard let senderPID = event.attributeDescriptor(forKeyword: keySenderPIDAttr)?.int32Value,
              senderPID > 0 else {
            return [:]
        }
        return ["senderPID": String(senderPID)]
    }
}
