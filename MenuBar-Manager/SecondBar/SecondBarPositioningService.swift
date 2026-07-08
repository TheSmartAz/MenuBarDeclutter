import AppKit
import CoreGraphics
import Foundation

enum SecondBarPositionMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case belowMenuBar
    case nearMouse
    case lastPosition

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .belowMenuBar:
            "Below Menu Bar"
        case .nearMouse:
            "Near Mouse"
        case .lastPosition:
            "Last Position"
        }
    }
}

struct SecondBarScreenSnapshot: Equatable, Sendable {
    let id: String
    let frame: CGRect
    let visibleFrame: CGRect
    let isMain: Bool
    let notchAvoidanceRect: CGRect?

    init(
        id: String,
        frame: CGRect,
        visibleFrame: CGRect,
        isMain: Bool = false,
        notchAvoidanceRect: CGRect? = nil
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.isMain = isMain
        self.notchAvoidanceRect = notchAvoidanceRect
    }
}

struct SecondBarPlacement: Equatable, Sendable {
    let frame: CGRect
    let screenID: String
    let avoidedNotch: Bool
}

struct SecondBarPositioningService {
    var screensProvider: () -> [SecondBarScreenSnapshot]
    var mouseLocationProvider: () -> CGPoint

    init(
        screensProvider: @escaping () -> [SecondBarScreenSnapshot] = { Self.currentScreens() },
        mouseLocationProvider: @escaping () -> CGPoint = { NSEvent.mouseLocation }
    ) {
        self.screensProvider = screensProvider
        self.mouseLocationProvider = mouseLocationProvider
    }

    func currentScreenSnapshots() -> [SecondBarScreenSnapshot] {
        screensProvider()
    }

    func invalidateCurrentScreenSnapshots() {
        Self.invalidateCurrentScreens()
    }

    func placement(
        panelSize: CGSize,
        mode: SecondBarPositionMode,
        lastPosition: CGPoint? = nil
    ) -> SecondBarPlacement {
        placement(
            panelSize: panelSize,
            mode: mode,
            mouseLocation: mouseLocationProvider(),
            lastPosition: lastPosition,
            screens: screensProvider()
        )
    }

    func compactStripPlacement(
        contentSize: CGSize,
        anchorFrame: CGRect?
    ) -> SecondBarPlacement {
        compactStripPlacement(
            contentSize: contentSize,
            anchorFrame: anchorFrame,
            mouseLocation: mouseLocationProvider(),
            screens: screensProvider()
        )
    }

    func compactStripPlacement(
        contentSize: CGSize,
        anchorFrame: CGRect?,
        mouseLocation: CGPoint,
        screens: [SecondBarScreenSnapshot]
    ) -> SecondBarPlacement {
        let screen = chosenCompactStripScreen(
            anchorFrame: anchorFrame,
            mouseLocation: mouseLocation,
            screens: screens
        )
        let horizontalInset: CGFloat = 8
        let topInset: CGFloat = 6
        let rightEdge = screen.visibleFrame.maxX - horizontalInset
        let minimumUsableWidth = min(contentSize.width, max(0, screen.visibleFrame.width - (horizontalInset * 2)))

        let anchorLeft = anchorFrame
            .flatMap { screen.frame.intersects($0) || screen.visibleFrame.intersects($0) ? $0.minX : nil }
        let anchorRegionWidth = anchorLeft.map { rightEdge - $0 } ?? 0
        let canUseAnchorRegion = anchorLeft != nil && anchorRegionWidth >= minimumUsableWidth

        let usedNotchRegion: Bool
        let proposedLeft: CGFloat
        if canUseAnchorRegion, let anchorLeft {
            proposedLeft = anchorLeft
            usedNotchRegion = false
        } else if let notch = screen.notchAvoidanceRect {
            proposedLeft = notch.minX
            usedNotchRegion = true
        } else {
            proposedLeft = rightEdge - minimumUsableWidth
            usedNotchRegion = false
        }

        let clampedLeft = min(
            max(proposedLeft, screen.visibleFrame.minX + horizontalInset),
            max(screen.visibleFrame.minX + horizontalInset, rightEdge - minimumUsableWidth)
        )
        let width = max(0, rightEdge - clampedLeft)
        let size = CGSize(width: width, height: contentSize.height)
        let origin = clampedOrigin(
            CGPoint(
                x: clampedLeft,
                y: screen.visibleFrame.maxY - contentSize.height - topInset
            ),
            panelSize: size,
            visibleFrame: screen.visibleFrame
        )

        return SecondBarPlacement(
            frame: CGRect(origin: origin, size: size),
            screenID: screen.id,
            avoidedNotch: usedNotchRegion
        )
    }

    func placement(
        panelSize: CGSize,
        mode: SecondBarPositionMode,
        mouseLocation: CGPoint,
        lastPosition: CGPoint?,
        screens: [SecondBarScreenSnapshot]
    ) -> SecondBarPlacement {
        let screen = chosenScreen(
            mode: mode,
            mouseLocation: mouseLocation,
            lastPosition: lastPosition,
            screens: screens
        )

        var origin: CGPoint
        switch mode {
        case .belowMenuBar:
            origin = belowMenuBarOrigin(panelSize: panelSize, screen: screen)
        case .nearMouse:
            origin = CGPoint(
                x: mouseLocation.x - (panelSize.width / 2),
                y: mouseLocation.y - panelSize.height - 12
            )
        case .lastPosition:
            origin = lastPosition ?? belowMenuBarOrigin(panelSize: panelSize, screen: screen)
        }

        origin = clampedOrigin(origin, panelSize: panelSize, visibleFrame: screen.visibleFrame)
        let beforeNotch = CGRect(origin: origin, size: panelSize)
        let adjusted = avoidNotchIfNeeded(frame: beforeNotch, screen: screen)
        let finalFrame = CGRect(
            origin: clampedOrigin(
                adjusted.frame.origin,
                panelSize: panelSize,
                visibleFrame: screen.visibleFrame
            ),
            size: panelSize
        )

        return SecondBarPlacement(
            frame: finalFrame,
            screenID: screen.id,
            avoidedNotch: adjusted.avoided
        )
    }

    private func chosenScreen(
        mode: SecondBarPositionMode,
        mouseLocation: CGPoint,
        lastPosition: CGPoint?,
        screens: [SecondBarScreenSnapshot]
    ) -> SecondBarScreenSnapshot {
        let fallback = screens.first(where: \.isMain) ?? screens.first ?? Self.fallbackScreen

        switch mode {
        case .nearMouse:
            return screens.first { $0.frame.contains(mouseLocation) } ?? fallback
        case .lastPosition:
            if let lastPosition,
               let screen = screens.first(where: { $0.visibleFrame.contains(lastPosition) || $0.frame.contains(lastPosition) }) {
                return screen
            }
            return screens.first { $0.frame.contains(mouseLocation) } ?? fallback
        case .belowMenuBar:
            return screens.first { $0.frame.contains(mouseLocation) }
                ?? screens.first(where: \.isMain)
                ?? fallback
        }
    }

    private func chosenCompactStripScreen(
        anchorFrame: CGRect?,
        mouseLocation: CGPoint,
        screens: [SecondBarScreenSnapshot]
    ) -> SecondBarScreenSnapshot {
        let fallback = screens.first(where: \.isMain) ?? screens.first ?? Self.fallbackScreen
        if let anchorFrame,
           let screen = screens.first(where: { $0.frame.intersects(anchorFrame) || $0.visibleFrame.intersects(anchorFrame) }) {
            return screen
        }
        return screens.first { $0.frame.contains(mouseLocation) }
            ?? screens.first(where: \.isMain)
            ?? fallback
    }

    private func belowMenuBarOrigin(panelSize: CGSize, screen: SecondBarScreenSnapshot) -> CGPoint {
        CGPoint(
            x: screen.visibleFrame.midX - (panelSize.width / 2),
            y: screen.visibleFrame.maxY - panelSize.height - 8
        )
    }

    private func clampedOrigin(
        _ origin: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        let width = min(panelSize.width, visibleFrame.width)
        let height = min(panelSize.height, visibleFrame.height)
        let maxX = visibleFrame.maxX - width
        let maxY = visibleFrame.maxY - height

        return CGPoint(
            x: min(max(origin.x, visibleFrame.minX), maxX),
            y: min(max(origin.y, visibleFrame.minY), maxY)
        )
    }

    private func avoidNotchIfNeeded(
        frame: CGRect,
        screen: SecondBarScreenSnapshot
    ) -> (frame: CGRect, avoided: Bool) {
        guard let notch = screen.notchAvoidanceRect,
              frame.intersects(notch) else {
            return (frame, false)
        }

        let leftX = notch.minX - frame.width - 8
        let rightX = notch.maxX + 8
        let leftFrame = CGRect(origin: CGPoint(x: leftX, y: frame.minY), size: frame.size)
        let rightFrame = CGRect(origin: CGPoint(x: rightX, y: frame.minY), size: frame.size)

        let leftFits = screen.visibleFrame.contains(leftFrame)
        let rightFits = screen.visibleFrame.contains(rightFrame)

        if rightFits {
            return (rightFrame, true)
        }
        if leftFits {
            return (leftFrame, true)
        }

        var shifted = frame
        shifted.origin.y = min(frame.minY, notch.minY - frame.height - 8)
        return (shifted, true)
    }

    static var fallbackScreen: SecondBarScreenSnapshot {
        SecondBarScreenSnapshot(
            id: "fallback",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            isMain: true
        )
    }

    static func currentScreens() -> [SecondBarScreenSnapshot] {
        currentScreenCache.snapshots()
    }

    static func invalidateCurrentScreens() {
        currentScreenCache.invalidate()
    }

    private static let currentScreenCache = SecondBarScreenSnapshotCache {
        uncachedCurrentScreens()
    }

    private static func uncachedCurrentScreens() -> [SecondBarScreenSnapshot] {
        NSScreen.screens.enumerated().map { index, screen in
            SecondBarScreenSnapshot(
                id: screen.localizedName.isEmpty ? "screen-\(index)" : screen.localizedName,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                isMain: screen == NSScreen.main,
                notchAvoidanceRect: notchAvoidanceRect(for: screen)
            )
        }
    }

    private static func notchAvoidanceRect(for screen: NSScreen) -> CGRect? {
        let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
        guard menuBarHeight > 0, screen.safeAreaInsets.top > 0 else {
            return nil
        }

        let notchWidth = min(240, screen.frame.width * 0.18)
        return CGRect(
            x: screen.frame.midX - (notchWidth / 2),
            y: screen.visibleFrame.maxY,
            width: notchWidth,
            height: menuBarHeight
        )
    }
}

final class SecondBarScreenSnapshotCache {
    private let snapshotsProvider: () -> [SecondBarScreenSnapshot]
    // Single-entry cache: one current display topology until a display-change invalidation.
    private var cachedSnapshots: [SecondBarScreenSnapshot]?

    init(snapshotsProvider: @escaping () -> [SecondBarScreenSnapshot]) {
        self.snapshotsProvider = snapshotsProvider
    }

    func snapshots() -> [SecondBarScreenSnapshot] {
        if let cachedSnapshots {
            return cachedSnapshots
        }

        let snapshots = snapshotsProvider()
        cachedSnapshots = snapshots
        return snapshots
    }

    func invalidate() {
        cachedSnapshots = nil
    }
}
