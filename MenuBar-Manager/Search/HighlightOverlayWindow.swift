import AppKit
import CoreGraphics
import Foundation

@MainActor
final class HighlightOverlayWindow {
    private let diagnosticsLogger: DiagnosticsLogger
    private var window: NSWindow?
    private var dismissWorkItem: DispatchWorkItem?

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    func show(around frame: CGRect, duration: TimeInterval = 2) {
        dismiss()

        let visibleFrame = visibleOverlayFrame(for: frame)
        guard visibleFrame.width > 0, visibleFrame.height > 0 else {
            diagnosticsLogger.log("Skipped search highlight because the target frame was empty.", level: .warning)
            return
        }

        let overlayWindow = window ?? makeWindow(frame: visibleFrame)
        overlayWindow.setFrame(visibleFrame, display: true)
        overlayWindow.contentView?.frame = NSRect(origin: .zero, size: visibleFrame.size)
        overlayWindow.orderFrontRegardless()

        window = overlayWindow

        let workItem = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.dismiss()
            }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        window?.orderOut(nil)
    }

    private func makeWindow(frame: CGRect) -> NSWindow {
        let overlayWindow = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.level = .statusBar
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        overlayWindow.contentView = HighlightOverlayView(frame: NSRect(origin: .zero, size: frame.size))
        return overlayWindow
    }

    private func visibleOverlayFrame(for frame: CGRect) -> CGRect {
        let padded = frame
            .standardized
            .insetBy(dx: -8, dy: -6)

        guard let screen = screen(containingOrNearestTo: padded) else {
            return padded
        }

        let screenFrame = screen.frame.insetBy(dx: 4, dy: 4)
        if screenFrame.intersects(padded) {
            return padded
        }

        let width = min(max(padded.width, 28), screenFrame.width)
        let height = min(max(padded.height, 24), screenFrame.height)
        let x = min(max(padded.midX - width / 2, screenFrame.minX), screenFrame.maxX - width)
        let y = min(max(padded.midY - height / 2, screenFrame.minY), screenFrame.maxY - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func screen(containingOrNearestTo frame: CGRect) -> NSScreen? {
        if let intersecting = NSScreen.screens.first(where: { $0.frame.intersects(frame) }) {
            return intersecting
        }

        let point = CGPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.min { lhs, rhs in
            distanceSquared(from: point, to: lhs.frame) < distanceSquared(from: point, to: rhs.frame)
        } ?? NSScreen.main
    }

    private func distanceSquared(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx: CGFloat
        if point.x < rect.minX {
            dx = rect.minX - point.x
        } else if point.x > rect.maxX {
            dx = point.x - rect.maxX
        } else {
            dx = 0
        }

        let dy: CGFloat
        if point.y < rect.minY {
            dy = rect.minY - point.y
        } else if point.y > rect.maxY {
            dy = point.y - rect.maxY
        } else {
            dy = 0
        }

        return dx * dx + dy * dy
    }
}

private final class HighlightOverlayView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.clear.setFill()
        dirtyRect.fill()

        let strokeRect = bounds.insetBy(dx: 3, dy: 3)
        let path = NSBezierPath(roundedRect: strokeRect, xRadius: 8, yRadius: 8)
        path.lineWidth = 3

        NSColor.controlAccentColor.withAlphaComponent(0.95).setStroke()
        path.stroke()

        NSColor.controlAccentColor.withAlphaComponent(0.12).setFill()
        path.fill()
    }
}
