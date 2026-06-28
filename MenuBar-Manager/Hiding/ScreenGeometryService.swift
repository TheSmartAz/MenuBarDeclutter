import AppKit
import Foundation

/// Computes geometry constants used to collapse menu bar items left of the
/// primary separator.
///
/// Collapsing relies on the fact that `NSStatusItem` instances in the menu bar
/// are arranged left-to-right in declaration order. A separator item whose
/// `length` exceeds the visible menu bar band pushes later-declared items left,
/// off the screen edge. ``ScreenGeometryService`` makes those length decisions
/// and keeps them isolated from AppKit so they remain unit-testable on a
/// headless test runner without an active display.
final class ScreenGeometryService {
    /// Provider that returns the width of every currently attached screen.
    /// Defaulting to a closure reading `NSScreen.screens` keeps the type
    /// usable in production while allowing tests to inject fake widths.
    private let widthsProvider: () -> [Double]
    private let screenFramesProvider: () -> [CGRect]
    private let primaryScreenFrameProvider: () -> CGRect?
    private let menuBarBandsProvider: () -> [CGRect]
    private var cachedWidths: [Double]?
    private var cachedScreenFrames: [CGRect]?
    private var cachedMenuBarBands: [CGRect]?

    init(
        widthsProvider: @escaping () -> [Double] = { NSScreen.screens.map { Double($0.frame.width) } },
        screenFramesProvider: @escaping () -> [CGRect] = { NSScreen.screens.map(\.frame) },
        primaryScreenFrameProvider: @escaping () -> CGRect? = { NSScreen.main?.frame },
        menuBarBandsProvider: (() -> [CGRect])? = nil
    ) {
        self.widthsProvider = widthsProvider
        self.screenFramesProvider = screenFramesProvider
        self.primaryScreenFrameProvider = primaryScreenFrameProvider
        self.menuBarBandsProvider = menuBarBandsProvider ?? {
            NSScreen.screens.compactMap { Self.menuBarBand(for: $0) }
        }
    }

    /// Clears cached screen geometry after a display-configuration change.
    func invalidateCache() {
        cachedWidths = nil
        cachedScreenFrames = nil
        cachedMenuBarBands = nil
    }

    /// Returns the widest visible menu bar width across all currently attached
    /// screens. Falls back to a positive constant when no screen is available
    /// (e.g., running inside a headless test runner) so callers can still
    /// produce a sane collapsed length.
    func widestScreenWidth() -> Double {
        let width = widths().max() ?? 0
        return width > 0 ? width : 1
    }

    /// Recommended length for the collapsed separator.
    ///
    /// Formula: `max(widestScreenWidth * 2, minimum)` capped at
    /// ``AppConstants/collapsedSeparatorMaximumLength``.
    func recommendedCollapsedSeparatorLength() -> Double {
        let scaled = widestScreenWidth() * AppConstants.collapsedSeparatorWidthMultiplier
        let floored = max(scaled, AppConstants.collapsedSeparatorMinimumLength)
        return min(floored, AppConstants.collapsedSeparatorMaximumLength)
    }

    /// Vertical band of the menu bar on a given screen, in screen coordinates.
    /// Returns `nil` when the screen cannot be queried (headless environment).
    /// On macOS 26+ the menu bar lives only on the primary screen; this helper
    /// still returns the top strip of any screen so callers can hit-test
    /// uniformly regardless of which screen the cursor is on.
    func menuBarBand(for screen: NSScreen) -> CGRect? {
        Self.menuBarBand(for: screen)
    }

    /// Returns the screen frame that should bound planning for an item frame.
    /// An intersecting screen wins; otherwise the primary screen, first known
    /// screen, or headless fallback is used.
    func screenFrame(intersecting itemFrame: CGRect) -> CGRect {
        let frames = screenFrames()
        if let matchingFrame = frames.first(where: { $0.intersects(itemFrame) || $0.contains(CGPoint(x: itemFrame.midX, y: itemFrame.midY)) }) {
            return matchingFrame
        }

        return primaryScreenFrameProvider()
            ?? frames.first
            ?? AppConstants.defaultScreenFrame
    }

    private static func menuBarBand(for screen: NSScreen) -> CGRect? {
        let frame = screen.frame
        let menuBarHeight = max(0, frame.maxY - screen.visibleFrame.maxY)
        guard menuBarHeight > 0 else { return nil }

        let originY = frame.maxY - menuBarHeight
        return CGRect(x: frame.minX, y: originY, width: frame.width, height: menuBarHeight)
    }

    /// Returns `true` when `point` is inside the menu bar band of any screen.
    func isPointInAnyMenuBarBand(_ point: CGPoint) -> Bool {
        menuBarBands().contains { band in
            band.contains(point)
        }
    }

    private func widths() -> [Double] {
        if let cachedWidths {
            return cachedWidths
        }

        let widths = widthsProvider()
        cachedWidths = widths
        return widths
    }

    private func screenFrames() -> [CGRect] {
        if let cachedScreenFrames {
            return cachedScreenFrames
        }

        let frames = screenFramesProvider()
        cachedScreenFrames = frames
        return frames
    }

    private func menuBarBands() -> [CGRect] {
        if let cachedMenuBarBands {
            return cachedMenuBarBands
        }

        let bands = menuBarBandsProvider()
        cachedMenuBarBands = bands
        return bands
    }
}
