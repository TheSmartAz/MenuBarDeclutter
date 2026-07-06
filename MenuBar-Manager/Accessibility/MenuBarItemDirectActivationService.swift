import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

nonisolated struct MenuBarItemDirectActivationResult: Equatable, Sendable {
    enum Status: String, Equatable, Sendable {
        case success
        case targetNotFound
        case actionFailed
        case missingTargetMetadata
    }

    let status: Status
    let message: String
    let visitedElementCount: Int
    let axErrorDescription: String?

    var didActivate: Bool { status == .success }

    static func success(visitedElementCount: Int) -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .success,
            message: "Menu bar item activated.",
            visitedElementCount: visitedElementCount,
            axErrorDescription: nil
        )
    }

    static func targetNotFound(visitedElementCount: Int) -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .targetNotFound,
            message: "Matching menu bar item was not found.",
            visitedElementCount: visitedElementCount,
            axErrorDescription: nil
        )
    }

    static func actionFailed(
        error: AXError,
        visitedElementCount: Int
    ) -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .actionFailed,
            message: "Menu bar item did not accept AXPress.",
            visitedElementCount: visitedElementCount,
            axErrorDescription: "\(error)"
        )
    }

    static func missingTargetMetadata() -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .missingTargetMetadata,
            message: "Menu bar item target metadata is incomplete.",
            visitedElementCount: 0,
            axErrorDescription: nil
        )
    }
}

@MainActor
final class MenuBarItemDirectActivationService {
    private struct ElementIdentity {
        let title: String?
        let role: String?
        let subrole: String?
        let frame: CGRect?
        let processIdentifier: pid_t?
        let bundleIdentifier: String?
    }

    private let diagnosticsLogger: DiagnosticsLogger
    private let reader: AXElementReader
    private let runningApplicationsProvider: () -> [RunningApplicationSnapshot]
    private let maxDepth = 6
    private let maxElements = 260

    init(
        diagnosticsLogger: DiagnosticsLogger,
        reader: AXElementReader = AXElementReader(),
        runningApplicationsProvider: @escaping () -> [RunningApplicationSnapshot] = {
            NSWorkspace.shared.runningApplications
                .filter { $0.isTerminated == false }
                .map {
                    RunningApplicationSnapshot(
                        processIdentifier: $0.processIdentifier,
                        bundleIdentifier: $0.bundleIdentifier,
                        localizedName: $0.localizedName
                    )
                }
        }
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.reader = reader
        self.runningApplicationsProvider = runningApplicationsProvider
    }

    func activate(snapshot: MenuBarItemSnapshot) -> MenuBarItemDirectActivationResult {
        guard snapshot.owningProcessIdentifier != nil || snapshot.bundleIdentifier != nil else {
            return .missingTargetMetadata()
        }

        reader.resetFailureCount()
        let runningApplications = runningApplicationsProvider()
        let runningApplicationsByPID = Dictionary(
            uniqueKeysWithValues: runningApplications.map { ($0.processIdentifier, $0) }
        )
        var visitedElementCount = 0
        let roots = candidateRoots(
            for: snapshot,
            runningApplications: runningApplications,
            runningApplicationsByPID: runningApplicationsByPID
        )

        for root in roots {
            if let element = findMatchingElement(
                from: root,
                inheritedProcessIdentifier: nil,
                target: snapshot,
                runningApplicationsByPID: runningApplicationsByPID,
                depth: 0,
                visitedElementCount: &visitedElementCount
            ) {
                let error = AXUIElementPerformAction(element, kAXPressAction as CFString)
                guard error == .success else {
                    diagnosticsLogger.log(
                        "Direct activation AXPress failed for \(snapshot.id): \(error).",
                        level: .warning,
                        category: .layout
                    )
                    return .actionFailed(error: error, visitedElementCount: visitedElementCount)
                }

                diagnosticsLogger.log(
                    "Direct activation AXPress succeeded for \(snapshot.id).",
                    level: .debug,
                    category: .layout
                )
                return .success(visitedElementCount: visitedElementCount)
            }

            if visitedElementCount >= maxElements {
                break
            }
        }

        diagnosticsLogger.log(
            "Direct activation could not find \(snapshot.id) after \(visitedElementCount) AX elements.",
            level: .warning,
            category: .layout
        )
        return .targetNotFound(visitedElementCount: visitedElementCount)
    }

    private func candidateRoots(
        for snapshot: MenuBarItemSnapshot,
        runningApplications: [RunningApplicationSnapshot],
        runningApplicationsByPID: [pid_t: RunningApplicationSnapshot]
    ) -> [AXUIElement] {
        var roots: [AXUIElement] = []
        if let processIdentifier = snapshot.owningProcessIdentifier {
            let app = runningApplicationsByPID[processIdentifier] ?? RunningApplicationSnapshot(
                processIdentifier: processIdentifier,
                bundleIdentifier: snapshot.bundleIdentifier,
                localizedName: snapshot.owningApplicationName
            )
            roots.append(contentsOf: applicationCandidateRoots(for: app))
        } else if let bundleIdentifier = snapshot.bundleIdentifier,
                  let app = runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
            roots.append(contentsOf: applicationCandidateRoots(for: app))
        }

        roots.append(contentsOf: systemWideCandidateRoots())
        return roots
    }

    private func systemWideCandidateRoots() -> [AXUIElement] {
        let systemWide = AXUIElementCreateSystemWide()
        var roots: [AXUIElement] = []

        for attribute in ["AXExtrasMenuBar", kAXMenuBarAttribute as String] {
            if let root = reader.readOptionalElement(systemWide, attribute: attribute) {
                roots.append(root)
                roots.append(contentsOf: reader.readChildren(root))
            }
        }

        return roots
    }

    private func applicationCandidateRoots(for app: RunningApplicationSnapshot) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var roots: [AXUIElement] = []

        for attribute in AXMenuBarScanner.applicationCandidateRootAttributes(for: app) {
            if let root = reader.readOptionalElement(appElement, attribute: attribute) {
                roots.append(root)
                roots.append(contentsOf: reader.readChildren(root))
            }
        }

        return roots
    }

    private func findMatchingElement(
        from element: AXUIElement,
        inheritedProcessIdentifier: pid_t?,
        target: MenuBarItemSnapshot,
        runningApplicationsByPID: [pid_t: RunningApplicationSnapshot],
        depth: Int,
        visitedElementCount: inout Int
    ) -> AXUIElement? {
        guard depth <= maxDepth,
              visitedElementCount < maxElements else {
            return nil
        }

        visitedElementCount += 1
        let identity = identity(
            for: element,
            inheritedProcessIdentifier: inheritedProcessIdentifier,
            runningApplicationsByPID: runningApplicationsByPID
        )

        if matches(identity, target: target) {
            return element
        }

        if shouldPruneDescendants(role: identity.role, subrole: identity.subrole) {
            return nil
        }

        for child in reader.readChildren(element) {
            if let match = findMatchingElement(
                from: child,
                inheritedProcessIdentifier: identity.processIdentifier,
                target: target,
                runningApplicationsByPID: runningApplicationsByPID,
                depth: depth + 1,
                visitedElementCount: &visitedElementCount
            ) {
                return match
            }

            if visitedElementCount >= maxElements {
                return nil
            }
        }

        return nil
    }

    private func identity(
        for element: AXUIElement,
        inheritedProcessIdentifier: pid_t?,
        runningApplicationsByPID: [pid_t: RunningApplicationSnapshot]
    ) -> ElementIdentity {
        let pid = reader.readProcessIdentifier(element) ?? inheritedProcessIdentifier
        let app = pid.flatMap { runningApplicationsByPID[$0] }
        return ElementIdentity(
            title: DisplayString.firstNonEmpty([
                reader.readOptionalString(element, attribute: kAXTitleAttribute as String),
                reader.readOptionalString(element, attribute: kAXDescriptionAttribute as String),
                reader.readOptionalString(element, attribute: "AXIdentifier")
            ]),
            role: reader.readString(element, attribute: kAXRoleAttribute as String),
            subrole: reader.readOptionalString(element, attribute: kAXSubroleAttribute as String),
            frame: reader.readFrame(element),
            processIdentifier: pid,
            bundleIdentifier: app?.bundleIdentifier
        )
    }

    private func matches(
        _ identity: ElementIdentity,
        target: MenuBarItemSnapshot
    ) -> Bool {
        let stableID = MenuBarItemSnapshot.stableID(
            title: identity.title,
            role: identity.role,
            subrole: identity.subrole,
            frame: identity.frame,
            owningProcessIdentifier: identity.processIdentifier,
            bundleIdentifier: identity.bundleIdentifier ?? target.bundleIdentifier
        )
        if stableID == target.id {
            return true
        }

        guard ownerMatches(identity, target: target),
              identity.role == target.role,
              identity.subrole == target.subrole,
              titlesMatch(identity.title, target.title),
              framesMatch(identity.frame, target.frame) else {
            return false
        }

        return true
    }

    private func ownerMatches(
        _ identity: ElementIdentity,
        target: MenuBarItemSnapshot
    ) -> Bool {
        if let targetBundle = target.bundleIdentifier,
           let bundleIdentifier = identity.bundleIdentifier {
            return targetBundle == bundleIdentifier
        }
        if let targetPID = target.owningProcessIdentifier,
           let processIdentifier = identity.processIdentifier {
            return targetPID == processIdentifier
        }
        return false
    }

    private func titlesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            true
        case (.some(let lhs), .some(let rhs)):
            lhs == rhs
        default:
            false
        }
    }

    private func framesMatch(_ lhs: CGRect?, _ rhs: CGRect?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            true
        case (.some(let lhs), .some(let rhs)):
            rounded(lhs) == rounded(rhs)
        default:
            false
        }
    }

    private func rounded(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.origin.x.rounded(),
            y: frame.origin.y.rounded(),
            width: frame.size.width.rounded(),
            height: frame.size.height.rounded()
        )
    }

    private func shouldPruneDescendants(role: String?, subrole: String?) -> Bool {
        if role == "AXMenu" || role == "AXMenuItem" {
            return true
        }

        let text = [role, subrole]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        return text.contains("menubaritem")
            || text.contains("menu bar item")
            || text.contains("statusitem")
            || text.contains("menuextra")
            || text.contains("menu extra")
    }
}
