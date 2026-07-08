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

    enum MatrixOutcome: String, Equatable, Sendable {
        case pass = "PASS"
        case failTargetNotFound = "FAIL_TARGET_NOT_FOUND"
        case failAXPress = "FAIL_AX_PRESS"
        case failMissingMetadata = "FAIL_MISSING_METADATA"
    }

    let status: Status
    let message: String
    let visitedElementCount: Int
    let axErrorDescription: String?

    var didActivate: Bool { status == .success }

    var matrixOutcome: MatrixOutcome {
        switch status {
        case .success:
            .pass
        case .targetNotFound:
            .failTargetNotFound
        case .actionFailed:
            .failAXPress
        case .missingTargetMetadata:
            .failMissingMetadata
        }
    }

    static func success(
        visitedElementCount: Int,
        message: String = "Menu bar item activated."
    ) -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .success,
            message: message,
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
        actionFailed(
            errorDescription: "\(error)",
            visitedElementCount: visitedElementCount
        )
    }

    static func actionFailed(
        errorDescription: String,
        visitedElementCount: Int
    ) -> MenuBarItemDirectActivationResult {
        MenuBarItemDirectActivationResult(
            status: .actionFailed,
            message: "Menu bar item did not accept activation actions.",
            visitedElementCount: visitedElementCount,
            axErrorDescription: errorDescription
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

nonisolated enum MenuBarItemDirectActivationClickFallback {
    static func canClick(frame: CGRect, screenFrames: [CGRect]) -> Bool {
        guard frame.origin.x.isFinite,
              frame.origin.y.isFinite,
              frame.size.width.isFinite,
              frame.size.height.isFinite,
              frame.width >= 4,
              frame.height >= 4,
              frame.width <= 320,
              frame.height <= 44 else {
            return false
        }

        return screenFrames.contains { screenFrame in
            guard screenFrame.intersects(frame) else { return false }

            let bottomOriginTopInset = abs(screenFrame.maxY - frame.maxY)
            let bottomOriginTopBand = frame.minY >= screenFrame.maxY - 60
                && frame.maxY <= screenFrame.maxY + 8
            let topOriginTopInset = abs(frame.minY - screenFrame.minY)
            let topOriginTopBand = frame.minY >= screenFrame.minY - 8
                && frame.maxY <= screenFrame.minY + 60
            return (bottomOriginTopInset <= 8 && bottomOriginTopBand)
                || (topOriginTopInset <= 8 && topOriginTopBand)
        }
    }

    @MainActor
    static func click(frame: CGRect) -> Bool {
        guard canClick(frame: frame, screenFrames: NSScreen.screens.map(\.frame)),
              let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        let point = CGPoint(x: frame.midX, y: frame.midY)
        guard let mouseDown = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ),
            let mouseUp = CGEvent(
                mouseEventSource: source,
                mouseType: .leftMouseUp,
                mouseCursorPosition: point,
                mouseButton: .left
            ) else {
            return false
        }

        mouseDown.post(tap: .cghidEventTap)
        mouseUp.post(tap: .cghidEventTap)
        return true
    }
}

nonisolated enum MenuBarItemDirectActivationMatcher {
    struct Identity: Equatable, Sendable {
        let title: String?
        let role: String?
        let subrole: String?
        let frame: CGRect?
        let processIdentifier: pid_t?
        let bundleIdentifier: String?
    }

    static func matches(
        _ identity: Identity,
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
              identity.subrole == target.subrole else {
            return false
        }

        if titlesMatch(identity.title, target.title),
           framesMatch(identity.frame, target.frame) {
            return true
        }

        return framesLikelySameMenuBarSlot(identity.frame, target.frame)
    }

    private static func ownerMatches(
        _ identity: Identity,
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

    private static func titlesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            true
        case (.some(let lhs), .some(let rhs)):
            lhs == rhs
        default:
            false
        }
    }

    private static func framesMatch(_ lhs: CGRect?, _ rhs: CGRect?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            true
        case (.some(let lhs), .some(let rhs)):
            rounded(lhs) == rounded(rhs)
        default:
            false
        }
    }

    private static func framesLikelySameMenuBarSlot(_ lhs: CGRect?, _ rhs: CGRect?) -> Bool {
        guard let lhs, let rhs else { return false }

        let roundedLHS = rounded(lhs)
        let roundedRHS = rounded(rhs)
        guard roundedLHS.width > 0,
              roundedLHS.height > 0,
              roundedRHS.width > 0,
              roundedRHS.height > 0 else {
            return false
        }

        let verticalCentersClose = abs(roundedLHS.midY - roundedRHS.midY) <= 2
        let heightsClose = abs(roundedLHS.height - roundedRHS.height) <= 4
        let horizontalOverlap = max(
            CGFloat(0),
            min(roundedLHS.maxX, roundedRHS.maxX) - max(roundedLHS.minX, roundedRHS.minX)
        )
        let overlapRatio = horizontalOverlap / max(CGFloat(1), min(roundedLHS.width, roundedRHS.width))
        let leftEdgesClose = abs(roundedLHS.minX - roundedRHS.minX) <= 3
        let rightEdgesClose = abs(roundedLHS.maxX - roundedRHS.maxX) <= 3
        let centersClose = abs(roundedLHS.midX - roundedRHS.midX) <= 4
        let widthsClose = abs(roundedLHS.width - roundedRHS.width) <= 6

        guard verticalCentersClose, heightsClose else { return false }
        return overlapRatio >= 0.80
            || ((leftEdgesClose || rightEdgesClose) && overlapRatio >= 0.60)
            || (centersClose && widthsClose && overlapRatio >= 0.60)
    }

    private static func rounded(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.origin.x.rounded(),
            y: frame.origin.y.rounded(),
            width: frame.size.width.rounded(),
            height: frame.size.height.rounded()
        )
    }
}

@MainActor
final class MenuBarItemDirectActivationService {
    private struct MatchedElement {
        let element: AXUIElement
        let identity: MenuBarItemDirectActivationMatcher.Identity
    }

    private let diagnosticsLogger: DiagnosticsLogger
    private let reader: AXElementReader
    private let runningApplicationsProvider: () -> [RunningApplicationSnapshot]
    private let mouseClickFallback: @MainActor (CGRect) -> Bool
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
        },
        mouseClickFallback: @escaping @MainActor (CGRect) -> Bool = {
            MenuBarItemDirectActivationClickFallback.click(frame: $0)
        }
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.reader = reader
        self.runningApplicationsProvider = runningApplicationsProvider
        self.mouseClickFallback = mouseClickFallback
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
            if let match = findMatchingElement(
                from: root,
                inheritedProcessIdentifier: nil,
                target: snapshot,
                runningApplicationsByPID: runningApplicationsByPID,
                depth: 0,
                visitedElementCount: &visitedElementCount
            ) {
                return performActivationAction(
                    on: match.element,
                    snapshotID: snapshot.id,
                    itemFrame: match.identity.frame,
                    visitedElementCount: visitedElementCount
                )
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

    private func performActivationAction(
        on element: AXUIElement,
        snapshotID: String,
        itemFrame: CGRect?,
        visitedElementCount: Int
    ) -> MenuBarItemDirectActivationResult {
        let pressError = AXUIElementPerformAction(element, kAXPressAction as CFString)
        if pressError == .success {
            diagnosticsLogger.log(
                "Direct activation AXPress succeeded for \(snapshotID).",
                level: .debug,
                category: .layout
            )
            return .success(visitedElementCount: visitedElementCount)
        }

        let showMenuError = AXUIElementPerformAction(element, kAXShowMenuAction as CFString)
        if showMenuError == .success {
            diagnosticsLogger.log(
                "Direct activation AXShowMenu succeeded for \(snapshotID) after AXPress failed: \(pressError).",
                level: .debug,
                category: .layout
            )
            return .success(visitedElementCount: visitedElementCount)
        }

        if let itemFrame,
           mouseClickFallback(itemFrame) {
            diagnosticsLogger.log(
                "Direct activation CGEvent click fallback dispatched for \(snapshotID) after AX actions failed.",
                level: .debug,
                category: .layout
            )
            return .success(
                visitedElementCount: visitedElementCount,
                message: "Menu bar item activation click fallback dispatched."
            )
        }

        let clickFallbackDescription = itemFrame == nil
            ? "CGEvent fallback: missing frame"
            : "CGEvent fallback: unavailable"
        let errorDescription = "AXPress: \(pressError); AXShowMenu: \(showMenuError); \(clickFallbackDescription)"
        diagnosticsLogger.log(
            "Direct activation actions failed for \(snapshotID): \(errorDescription).",
            level: .warning,
            category: .layout
        )
        return .actionFailed(
            errorDescription: errorDescription,
            visitedElementCount: visitedElementCount
        )
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
    ) -> MatchedElement? {
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
            return MatchedElement(element: element, identity: identity)
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
    ) -> MenuBarItemDirectActivationMatcher.Identity {
        let pid = reader.readProcessIdentifier(element) ?? inheritedProcessIdentifier
        let app = pid.flatMap { runningApplicationsByPID[$0] }
        return MenuBarItemDirectActivationMatcher.Identity(
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
        _ identity: MenuBarItemDirectActivationMatcher.Identity,
        target: MenuBarItemSnapshot
    ) -> Bool {
        MenuBarItemDirectActivationMatcher.matches(identity, target: target)
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
