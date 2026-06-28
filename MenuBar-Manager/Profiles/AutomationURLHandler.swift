import AppKit
import Foundation

@MainActor
final class AutomationURLHandler {
    private let diagnosticsLogger: DiagnosticsLogger
    private let expand: () -> Void
    private let collapse: () -> Void
    private let revealAll: () -> Void
    private let showSecondBar: () -> Void
    private let applyProfileNamed: (String) -> Bool

    init(
        diagnosticsLogger: DiagnosticsLogger,
        expand: @escaping () -> Void,
        collapse: @escaping () -> Void,
        revealAll: @escaping () -> Void,
        showSecondBar: @escaping () -> Void,
        applyProfileNamed: @escaping (String) -> Bool
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.expand = expand
        self.collapse = collapse
        self.revealAll = revealAll
        self.showSecondBar = showSecondBar
        self.applyProfileNamed = applyProfileNamed
    }

    func install() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        diagnosticsLogger.log("Automation URL handler installed.", level: .debug)
    }

    func uninstall() {
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme == "menubardeclutter" else { return false }

        let host = url.host(percentEncoded: false) ?? ""
        let path = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "expand":
            expand()
            diagnosticsLogger.log("Automation URL: expand.")
            return true
        case "collapse":
            collapse()
            diagnosticsLogger.log("Automation URL: collapse.")
            return true
        case "reveal-all", "revealAll":
            revealAll()
            diagnosticsLogger.log("Automation URL: reveal all.")
            return true
        case "second-bar", "show-second-bar":
            showSecondBar()
            diagnosticsLogger.log("Automation URL: show second bar.")
            return true
        case "profile":
            guard let name = path.first?.removingPercentEncoding, !name.isEmpty else {
                diagnosticsLogger.log("Automation URL profile command missing a profile name.", level: .warning)
                return false
            }
            let didApply = applyProfileNamed(name)
            diagnosticsLogger.log(
                didApply
                    ? "Automation URL: applied profile \(name)."
                    : "Automation URL: profile \(name) not found.",
                level: didApply ? .info : .warning
            )
            return didApply
        default:
            diagnosticsLogger.log("Unknown automation URL command: \(url.absoluteString)", level: .warning)
            return false
        }
    }

    @objc private func handleGetURLEvent(
        _ event: NSAppleEventDescriptor,
        withReplyEvent replyEvent: NSAppleEventDescriptor
    ) {
        guard let rawURL = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: rawURL) else {
            diagnosticsLogger.log("Automation URL event missing URL.", level: .warning)
            return
        }

        _ = handle(url: url)
    }
}
