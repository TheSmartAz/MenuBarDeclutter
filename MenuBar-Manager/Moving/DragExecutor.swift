import AppKit
import CoreGraphics
import Foundation

nonisolated protocol DragExecuting {
    func execute(_ plan: DragPlan) async -> Bool
}

nonisolated struct DragExecutor: DragExecuting {
    var eventSourceFactory: () -> CGEventSource?
    var currentMouseLocationProvider: (CGEventSource) -> CGPoint?
    var mouseMovePoster: (CGPoint, CGEventSource) -> Void
    var mouseEventPoster: (CGEventType, CGPoint, CGEventSource, CGEventFlags) -> Void
    var pauseHandler: (TimeInterval) async -> Bool
    var restoreMousePosition: Bool = true

    init(
        eventSourceFactory: @escaping () -> CGEventSource? = {
            CGEventSource(stateID: .hidSystemState)
        },
        currentMouseLocationProvider: @escaping (CGEventSource) -> CGPoint? = {
            CGEvent(source: $0)?.location
        },
        mouseMovePoster: @escaping (CGPoint, CGEventSource) -> Void = { point, source in
            Self.postMouseMove(to: point, source: source)
        },
        mouseEventPoster: @escaping (CGEventType, CGPoint, CGEventSource, CGEventFlags) -> Void = { type, point, source, flags in
            Self.postMouse(type, at: point, source: source, flags: flags)
        },
        pauseHandler: @escaping (TimeInterval) async -> Bool = AsyncPause.sleep,
        restoreMousePosition: Bool = true
    ) {
        self.eventSourceFactory = eventSourceFactory
        self.currentMouseLocationProvider = currentMouseLocationProvider
        self.mouseMovePoster = mouseMovePoster
        self.mouseEventPoster = mouseEventPoster
        self.pauseHandler = pauseHandler
        self.restoreMousePosition = restoreMousePosition
    }

    func execute(_ plan: DragPlan) async -> Bool {
        guard !Task.isCancelled else {
            return false
        }

        guard let source = eventSourceFactory(),
              let currentMouse = currentMouseLocationProvider(source) else {
            return false
        }

        var didMouseDown = false
        var lastDragPoint = plan.sourcePoint

        func cancelActiveDrag() -> Bool {
            if didMouseDown {
                mouseEventPoster(.leftMouseUp, lastDragPoint, source, [])
            }
            return false
        }

        guard !Task.isCancelled else {
            return false
        }

        postMouseMove(to: plan.sourcePoint, source: source)
        guard await pauseHandler(0.08), !Task.isCancelled else {
            return false
        }

        postMouse(.leftMouseDown, at: plan.sourcePoint, source: source, flags: plan.modifierFlags)
        didMouseDown = true
        guard await pauseHandler(0.08), !Task.isCancelled else {
            return cancelActiveDrag()
        }

        let steps = max(4, Int(plan.duration / 0.025))
        for index in 1...steps {
            guard !Task.isCancelled else {
                return cancelActiveDrag()
            }

            let progress = CGFloat(index) / CGFloat(steps)
            let point = CGPoint(
                x: plan.sourcePoint.x + ((plan.targetPoint.x - plan.sourcePoint.x) * progress),
                y: plan.sourcePoint.y + ((plan.targetPoint.y - plan.sourcePoint.y) * progress)
            )
            postMouse(.leftMouseDragged, at: point, source: source, flags: plan.modifierFlags)
            lastDragPoint = point

            guard await pauseHandler(plan.duration / TimeInterval(steps)), !Task.isCancelled else {
                return cancelActiveDrag()
            }
        }

        postMouse(.leftMouseUp, at: plan.targetPoint, source: source, flags: [])
        didMouseDown = false

        if restoreMousePosition {
            guard await pauseHandler(0.08), !Task.isCancelled else {
                return false
            }
            postMouseMove(to: currentMouse, source: source)
        }

        return !Task.isCancelled
    }

    private func postMouseMove(to point: CGPoint, source: CGEventSource) {
        mouseMovePoster(point, source)
    }

    private func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        source: CGEventSource,
        flags: CGEventFlags
    ) {
        mouseEventPoster(type, point, source, flags)
    }

    private static func postMouseMove(to point: CGPoint, source: CGEventSource) {
        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private static func postMouse(
        _ type: CGEventType,
        at point: CGPoint,
        source: CGEventSource,
        flags: CGEventFlags
    ) {
        let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: .left
        )
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }

}
