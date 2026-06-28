import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

actor AXMenuBarScanner: MenuBarScanning {
    private struct ScannerLogEntry: Sendable {
        let message: String
        let level: DiagnosticLevel
    }

    private struct ScanOutput: Sendable {
        let result: MenuBarScanResult
        let logs: [ScannerLogEntry]
    }

    private let log: @MainActor @Sendable (String, DiagnosticLevel, DiagnosticCategory?) -> Void
    private let reader: AXElementReader
    private let now: @Sendable () -> Date
    private var candidateCache = AXMenuBarCandidateCache()

    private let maxDepth = 7
    private let maxElements = 700

    /// Roles that, when found on a child of the current element, indicate a dropdown
    /// menu subtree. We never record AXMenuItem snapshots (only the menu bar items
    /// themselves), so descending into these subtrees is wasted AX round-trips. Pruning
    /// here typically reduces the typical scan from hundreds of elements to ~20-30.
    nonisolated private static let prunableDescendantRoles: Set<String> = [
        "AXMenu",
        "AXMenuItem"
    ]
    nonisolated private static let menuBarItemRoleMarkers = [
        "menubaritem",
        "menu bar item",
        "statusitem",
        "menuextra",
        "menu extra"
    ]

    init(
        diagnosticsLogger: DiagnosticsLogger,
        reader: AXElementReader? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        let log: @MainActor @Sendable (String, DiagnosticLevel, DiagnosticCategory?) -> Void = { message, level, category in
            diagnosticsLogger.log(message, level: level, category: category)
        }
        self.log = log
        self.reader = reader ?? AXElementReader()
        self.now = now
    }

    func scan(context: MenuBarScanContext) async -> MenuBarScanResult {
        let output = performScan(context: context)
        for logEntry in output.logs {
            await log(logEntry.message, logEntry.level, .scan)
        }
        return output.result
    }

    private func performScan(context: MenuBarScanContext) -> ScanOutput {
        reader.resetFailureCount()

        let timestamp = now()
        let systemWide = AXUIElementCreateSystemWide()
        var traversedElementCount = 0
        var snapshots: [MenuBarItemSnapshot] = []
        var stoppedAtMaxElements = false
        var runningApplicationsByPID: [pid_t: RunningApplicationSnapshot] = [:]

        for app in context.runningApplications where runningApplicationsByPID[app.processIdentifier] == nil {
            runningApplicationsByPID[app.processIdentifier] = app
        }

        func collect(from roots: [AXUIElement]) {
            for root in roots {
                guard Task.isCancelled == false else { break }

                snapshots.append(
                    contentsOf: collectSnapshots(
                        from: root,
                        depth: 0,
                        inheritedProcessIdentifier: nil,
                        context: context,
                        runningApplicationsByPID: runningApplicationsByPID,
                        timestamp: timestamp,
                        traversedElementCount: &traversedElementCount
                    )
                )

                if traversedElementCount >= maxElements {
                    stoppedAtMaxElements = true
                    break
                }
            }
        }

        collect(from: systemWideCandidateRoots(systemWide: systemWide))

        if traversedElementCount < maxElements, Task.isCancelled == false {
            let runningProcessIdentifiers = context.runningApplications.map(\.processIdentifier)

            let orderedProcessIdentifiers = candidateCache.orderedProcessIdentifiers(
                forRunningProcessIdentifiers: runningProcessIdentifiers
            )
            var successfulProcessIdentifiers: [pid_t] = []
            var completedFullSweep = true

            for processIdentifier in orderedProcessIdentifiers {
                guard Task.isCancelled == false else {
                    completedFullSweep = false
                    break
                }
                guard let app = runningApplicationsByPID[processIdentifier] else { continue }
                let roots = applicationCandidateRoots(for: app)
                if roots.isEmpty == false {
                    successfulProcessIdentifiers.append(processIdentifier)
                    collect(from: roots)
                }

                if traversedElementCount >= maxElements {
                    completedFullSweep = false
                    break
                }
            }

            candidateCache.update(
                successfulProcessIdentifiers: successfulProcessIdentifiers,
                runningProcessIdentifiers: runningProcessIdentifiers,
                completedFullSweep: completedFullSweep
            )
        }

        let result = MenuBarScanResult(
            snapshots: snapshots,
            scanTimestamp: timestamp,
            axFailuresCount: reader.failureCount
        )
        var logs = reader.logMessages.map {
            ScannerLogEntry(message: $0, level: .debug)
        }
        if stoppedAtMaxElements {
            logs.append(ScannerLogEntry(
                message: "AX scan stopped after \(maxElements) elements.",
                level: .warning
            ))
        }
        logs.append(ScannerLogEntry(
            message: "AX menu bar scan read \(result.snapshots.count) item snapshots with \(result.axFailuresCount) AX failures.",
            level: .debug
        ))
        return ScanOutput(result: result, logs: logs)
    }

    func invalidateCandidateCache() {
        candidateCache.invalidate()
    }

    private func systemWideCandidateRoots(systemWide: AXUIElement) -> [AXUIElement] {
        var roots: [AXUIElement] = []

        for attribute in ["AXExtrasMenuBar", kAXMenuBarAttribute as String] {
            if let root = reader.readElement(systemWide, attribute: attribute) {
                roots.append(root)
                roots.append(contentsOf: reader.readChildren(root))
            }
        }

        return roots
    }

    private func applicationCandidateRoots(for app: RunningApplicationSnapshot) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var roots: [AXUIElement] = []

        // Each running application exposes its menu bar via `kAXMenuBarAttribute`;
        // for `systemuiserver`, the `AXExtrasMenuBar` attribute additionally surfaces
        // the system status items. The generic loop covers both cases, so the
        // previously-duplicated special-case block has been consolidated into the
        // per-app reads below.
        if let menuBar = reader.readElement(appElement, attribute: kAXMenuBarAttribute as String) {
            roots.append(menuBar)
            roots.append(contentsOf: reader.readChildren(menuBar))
        }

        if app.bundleIdentifier == "com.apple.systemuiserver"
            || app.localizedName == "SystemUIServer" {
            if let extras = reader.readElement(appElement, attribute: "AXExtrasMenuBar") {
                roots.append(extras)
                roots.append(contentsOf: reader.readChildren(extras))
            }
        }

        return roots
    }

    private func collectSnapshots(
        from element: AXUIElement,
        depth: Int,
        inheritedProcessIdentifier: pid_t?,
        context: MenuBarScanContext,
        runningApplicationsByPID: [pid_t: RunningApplicationSnapshot],
        timestamp: Date,
        traversedElementCount: inout Int
    ) -> [MenuBarItemSnapshot] {
        guard Task.isCancelled == false,
              depth <= maxDepth,
              traversedElementCount < maxElements else {
            return []
        }

        traversedElementCount += 1

        let pid = reader.readProcessIdentifier(element) ?? inheritedProcessIdentifier
        let role = reader.readString(element, attribute: kAXRoleAttribute as String)
        let subrole = reader.readString(element, attribute: kAXSubroleAttribute as String)
        let title = DisplayString.firstNonEmpty([
            reader.readString(element, attribute: kAXTitleAttribute as String),
            reader.readString(element, attribute: kAXDescriptionAttribute as String),
            reader.readString(element, attribute: "AXIdentifier")
        ])
        let frame = reader.readFrame(element)

        var snapshots: [MenuBarItemSnapshot] = []
        let isIncluded = shouldIncludeSnapshot(
            role: role,
            subrole: subrole,
            frame: frame,
            screenFrames: context.screenFrames
        )
        if isIncluded {
            let app = runningApplicationsByPID[pid ?? 0]
            let bundleIdentifier = app?.bundleIdentifier
            snapshots.append(
                MenuBarItemSnapshot(
                    title: title,
                    role: role,
                    subrole: subrole,
                    frame: frame,
                    owningProcessIdentifier: pid,
                    owningApplicationName: app?.localizedName,
                    bundleIdentifier: bundleIdentifier,
                    zone: MenuBarZone.classify(
                        itemFrame: frame,
                        primarySeparatorFrame: context.primarySeparatorFrame,
                        alwaysHiddenSeparatorFrame: context.alwaysHiddenSeparatorFrame
                    ),
                    isLikelySystemItem: Self.isLikelySystemItem(
                        bundleIdentifier: bundleIdentifier,
                        applicationName: app?.localizedName
                    ),
                    scanTimestamp: timestamp
                )
            )
        }

        // Prune descent into dropdown subtree. Once we have just captured (or are about
        // to capture) the menu bar item snapshot, descending into its `AXMenu` child
        // only gathers dropdown AXMenuItem nodes that are guaranteed to fail
        // `shouldIncludeSnapshot` — pure AX round-trip waste. Also skipped when the
        // current node's own role already marks it as a dropdown container or item.
        if Self.shouldPruneDescendants(
            ofIncludedNode: isIncluded,
            role: role,
            subrole: subrole
        ) {
            return snapshots
        }

        for child in reader.readChildren(element) {
            snapshots.append(
                contentsOf: collectSnapshots(
                    from: child,
                    depth: depth + 1,
                    inheritedProcessIdentifier: pid,
                    context: context,
                    runningApplicationsByPID: runningApplicationsByPID,
                    timestamp: timestamp,
                    traversedElementCount: &traversedElementCount
                )
            )
        }

        return snapshots
    }

    private func shouldIncludeSnapshot(
        role: String?,
        subrole: String?,
        frame: CGRect?,
        screenFrames: [CGRect]
    ) -> Bool {
        if Self.hasMenuBarItemRoleMarker(role: role, subrole: subrole) {
            return true
        }

        guard let frame, frame.width > 0, frame.height > 0, frame.height <= 40 else {
            return false
        }

        // Iterating the captured `[CGRect]` avoids the AppKit round-trip that the
        // previous `NSScreen.screens.contains { ... }` call paid on every visited
        // AX element.
        return screenFrames.contains { screenFrame in
            let topInset = abs(screenFrame.maxY - frame.maxY)
            return topInset <= 6 && screenFrame.intersects(frame)
        }
    }

    nonisolated static func shouldPruneDescendants(
        ofIncludedNode isIncluded: Bool,
        role: String?,
        subrole: String?
    ) -> Bool {
        if Self.prunableDescendantRoles.contains(role ?? "") {
            return true
        }

        return isIncluded && hasMenuBarItemRoleMarker(role: role, subrole: subrole)
    }

    private nonisolated static func hasMenuBarItemRoleMarker(role: String?, subrole: String?) -> Bool {
        let text = [role, subrole]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        return menuBarItemRoleMarkers.contains { text.contains($0) }
    }

    private nonisolated static func isLikelySystemItem(
        bundleIdentifier: String?,
        applicationName: String?
    ) -> Bool {
        if bundleIdentifier == "com.apple.systemuiserver" {
            return true
        }
        if bundleIdentifier?.hasPrefix("com.apple.") == true {
            return true
        }
        return applicationName == "SystemUIServer"
    }
}
