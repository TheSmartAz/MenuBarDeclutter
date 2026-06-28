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

        for root in candidateRoots(systemWide: systemWide) {
            snapshots.append(
                contentsOf: collectSnapshots(
                    from: root,
                    depth: 0,
                    inheritedProcessIdentifier: nil,
                    primarySeparatorFrame: primarySeparatorFrame,
                    alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame,
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
            if let menuBar = reader.readElement(appElement, attribute: kAXMenuBarAttribute as String) {
                roots.append(menuBar)
                roots.append(contentsOf: reader.readChildren(menuBar))
            }

            guard app.bundleIdentifier == "com.apple.systemuiserver"
                    || app.localizedName == "SystemUIServer" else {
                continue
            }

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
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?,
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
        if shouldIncludeSnapshot(role: role, subrole: subrole, frame: frame) {
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

        for child in reader.readChildren(element) {
            snapshots.append(
                contentsOf: collectSnapshots(
                    from: child,
                    depth: depth + 1,
                    inheritedProcessIdentifier: pid,
                    primarySeparatorFrame: primarySeparatorFrame,
                    alwaysHiddenSeparatorFrame: alwaysHiddenSeparatorFrame,
                    timestamp: timestamp,
                    traversedElementCount: &traversedElementCount
                )
            )
        }

        return snapshots
    }

    private func shouldIncludeSnapshot(role: String?, subrole: String?, frame: CGRect?) -> Bool {
        let text = [role, subrole]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if text.contains("menubaritem")
            || text.contains("menu bar item")
            || text.contains("statusitem")
            || text.contains("menuextra")
            || text.contains("menu extra") {
            return true
        }

        guard let frame, frame.width > 0, frame.height > 0, frame.height <= 40 else {
            return false
        }

        return NSScreen.screens.contains { screen in
            let topInset = abs(screen.frame.maxY - frame.maxY)
            return topInset <= 6 && screen.frame.intersects(frame)
        }
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
