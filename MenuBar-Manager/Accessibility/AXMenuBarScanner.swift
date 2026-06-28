import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
final class AXMenuBarScanner: MenuBarScanning {
    private let diagnosticsLogger: DiagnosticsLogger
    private let reader: AXElementReader
    private let now: () -> Date

    private let maxDepth = 7
    private let maxElements = 700

    /// Roles that, when found on a child of the current element, indicate a dropdown
    /// menu subtree. We never record AXMenuItem snapshots (only the menu bar items
    /// themselves), so descending into these subtrees is wasted AX round-trips. Pruning
    /// here typically reduces the typical scan from hundreds of elements to ~20-30.
    private static let prunableDescendantRoles: Set<String> = [
        "AXMenu",
        "AXMenuItem"
    ]
    private static let menuBarItemRoleMarkers = [
        "menubaritem",
        "menu bar item",
        "statusitem",
        "menuextra",
        "menu extra"
    ]

    init(
        diagnosticsLogger: DiagnosticsLogger,
        reader: AXElementReader? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.reader = reader ?? AXElementReader(diagnosticsLogger: diagnosticsLogger)
        self.now = now
    }

    func scan(
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?
    ) -> MenuBarScanResult {
        reader.resetFailureCount()

        let timestamp = now()
        let systemWide = AXUIElementCreateSystemWide()
        var traversedElementCount = 0
        var snapshots: [MenuBarItemSnapshot] = []

        // Capture NSScreen.screens once at the start of the scan; `shouldIncludeSnapshot`
        // previously re-queried AppKit on every visited element, which is a hot path
        // during a depth-first traversal.
        let screenFrames: [CGRect] = NSScreen.screens.map { $0.frame }

        for root in candidateRoots(systemWide: systemWide) {
            snapshots.append(
                contentsOf: collectSnapshots(
                    from: root,
                    depth: 0,
                    inheritedProcessIdentifier: nil,
                    primarySeparatorFrame: primarySeparatorFrame,
                    alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame,
                    screenFrames: screenFrames,
                    timestamp: timestamp,
                    traversedElementCount: &traversedElementCount
                )
            )

            if traversedElementCount >= maxElements {
                diagnosticsLogger.log("AX scan stopped after \(maxElements) elements.", level: .warning)
                break
            }
        }

        let result = MenuBarScanResult(
            snapshots: snapshots,
            scanTimestamp: timestamp,
            axFailuresCount: reader.failureCount
        )
        diagnosticsLogger.log(
            "AX menu bar scan read \(result.snapshots.count) item snapshots with \(result.axFailuresCount) AX failures.",
            level: .debug
        )
        return result
    }

    private func candidateRoots(systemWide: AXUIElement) -> [AXUIElement] {
        var roots: [AXUIElement] = []

        for attribute in ["AXExtrasMenuBar", kAXMenuBarAttribute as String] {
            if let root = reader.readElement(systemWide, attribute: attribute) {
                roots.append(root)
                roots.append(contentsOf: reader.readChildren(root))
            }
        }

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps where app.isTerminated == false {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
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
        }

        return roots
    }

    private func collectSnapshots(
        from element: AXUIElement,
        depth: Int,
        inheritedProcessIdentifier: pid_t?,
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?,
        screenFrames: [CGRect],
        timestamp: Date,
        traversedElementCount: inout Int
    ) -> [MenuBarItemSnapshot] {
        guard depth <= maxDepth, traversedElementCount < maxElements else {
            return []
        }

        traversedElementCount += 1

        let pid = reader.readProcessIdentifier(element) ?? inheritedProcessIdentifier
        let role = reader.readString(element, attribute: kAXRoleAttribute as String)
        let subrole = reader.readString(element, attribute: kAXSubroleAttribute as String)
        let title = firstNonEmpty([
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
            screenFrames: screenFrames
        )
        if isIncluded {
            let app = runningApplication(pid: pid)
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
                        primarySeparatorFrame: primarySeparatorFrame,
                        alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame
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
                    primarySeparatorFrame: primarySeparatorFrame,
                    alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame,
                    screenFrames: screenFrames,
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

    static func shouldPruneDescendants(
        ofIncludedNode isIncluded: Bool,
        role: String?,
        subrole: String?
    ) -> Bool {
        if Self.prunableDescendantRoles.contains(role ?? "") {
            return true
        }

        return isIncluded && hasMenuBarItemRoleMarker(role: role, subrole: subrole)
    }

    private static func hasMenuBarItemRoleMarker(role: String?, subrole: String?) -> Bool {
        let text = [role, subrole]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        return menuBarItemRoleMarkers.contains { text.contains($0) }
    }

    private func runningApplication(pid: pid_t?) -> NSRunningApplication? {
        guard let pid else { return nil }
        return NSRunningApplication(processIdentifier: pid)
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        values
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }
            .first
    }

    private static func isLikelySystemItem(
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
