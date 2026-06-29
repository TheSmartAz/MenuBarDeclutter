import AppKit
import Foundation

@MainActor
final class AutomationURLHandler {
    private enum Command: Hashable {
        case expand
        case collapse
        case revealAll
        case secondBar
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
    private let expand: () -> Void
    private let collapse: () -> Void
    private let revealAll: () -> Void
    private let showSecondBar: () -> Void
    private let applyProfileNamed: (String) -> Bool
    private let isAutomationEnabled: () -> Bool
    private let enterFullMenuBarMode: () -> Void
    private let exitFullMenuBarMode: () -> Void
    private let showLayoutSuggestions: () -> Void
    private let now: () -> Date
    private let minimumCommandInterval: TimeInterval

    private var lastAcceptedAtByCommand: [Command: Date] = [:]
    private var isInstalled = false

    init(
        diagnosticsLogger: DiagnosticsLogger,
        expand: @escaping () -> Void,
        collapse: @escaping () -> Void,
        revealAll: @escaping () -> Void,
        showSecondBar: @escaping () -> Void,
        applyProfileNamed: @escaping (String) -> Bool,
        isAutomationEnabled: @escaping () -> Bool = { true },
        enterFullMenuBarMode: @escaping () -> Void = {},
        exitFullMenuBarMode: @escaping () -> Void = {},
        showLayoutSuggestions: @escaping () -> Void = {},
        now: @escaping () -> Date = { Date() },
        minimumCommandInterval: TimeInterval = AutomationURLHandler.defaultMinimumCommandInterval
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.expand = expand
        self.collapse = collapse
        self.revealAll = revealAll
        self.showSecondBar = showSecondBar
        self.applyProfileNamed = applyProfileNamed
        self.isAutomationEnabled = isAutomationEnabled
        self.enterFullMenuBarMode = enterFullMenuBarMode
        self.exitFullMenuBarMode = exitFullMenuBarMode
        self.showLayoutSuggestions = showLayoutSuggestions
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

        if isAutomationEnabled() {
            diagnosticsLogger.log(
                "Automation URL handler installed.",
                level: .debug,
                category: .urlAutomation
            )
        } else {
            diagnosticsLogger.log(
                "Automation URL handler installed while automation is paused; URL commands will be rejected until automation resumes.",
                level: .info,
                category: .urlAutomation
            )
        }
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

        guard isAutomationEnabled() else {
            logRejection(
                "automation paused",
                metadata: eventMetadata,
                level: .info
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

        switch command {
        case .expand:
            expand()
            logSuccess("expand", command: command, metadata: eventMetadata)
            return true
        case .collapse:
            collapse()
            logSuccess("collapse", command: command, metadata: eventMetadata)
            return true
        case .revealAll:
            revealAll()
            logSuccess("reveal all", command: command, metadata: eventMetadata)
            return true
        case .secondBar:
            showSecondBar()
            logSuccess("show second bar", command: command, metadata: eventMetadata)
            return true
        case .profile:
            guard let name = profileName(from: url), !name.isEmpty else {
                logRejection(
                    "profile command missing profile name",
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName
                    ])
                )
                return false
            }
            let didApply = applyProfileNamed(name)
            if didApply {
                diagnosticsLogger.log(
                    "Automation URL applied profile.",
                    level: .info,
                    category: .urlAutomation,
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName,
                        "profile": name
                    ])
                )
            } else {
                logRejection(
                    "profile not found",
                    metadata: metadata(eventMetadata, adding: [
                        "command": command.logName,
                        "profile": name
                    ])
                )
            }
            return didApply
        case .fullMenuBar:
            enterFullMenuBarMode()
            logSuccess("enter full menu bar mode", command: command, metadata: eventMetadata)
            return true
        case .exitFullMenuBar:
            exitFullMenuBarMode()
            logSuccess("exit full menu bar mode", command: command, metadata: eventMetadata)
            return true
        case .layoutSuggestions:
            showLayoutSuggestions()
            logSuccess("show layout suggestions", command: command, metadata: eventMetadata)
            return true
        }
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

    private func logSuccess(_ action: String, command: Command, metadata eventMetadata: [String: String]) {
        diagnosticsLogger.log(
            "Automation URL command handled: \(action).",
            level: .info,
            category: .urlAutomation,
            metadata: metadata(eventMetadata, adding: [
                "command": command.logName
            ])
        )
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
