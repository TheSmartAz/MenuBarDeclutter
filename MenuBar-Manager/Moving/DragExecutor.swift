import AppKit
import CoreGraphics
import Foundation

nonisolated protocol DragExecuting {
    func execute(_ plan: DragPlan) async -> Bool
}

nonisolated struct DragExecutor: DragExecuting {
    var eventSourceFactory: () -> CGEventSource? = {
        CGEventSource(stateID: .hidSystemState)
    }
    var restoreMousePosition: Bool = true

    func execute(_ plan: DragPlan) async -> Bool {
        guard let source = eventSourceFactory(),
              let currentMouse = CGEvent(source: source)?.location else {
            return false
        }

        postMouseMove(to: plan.sourcePoint, source: source)
        await pause(0.08)
        postMouse(.leftMouseDown, at: plan.sourcePoint, source: source, flags: plan.modifierFlags)
        await pause(0.08)

        let steps = max(4, Int(plan.duration / 0.025))
        for index in 1...steps {
            let progress = CGFloat(index) / CGFloat(steps)
            let point = CGPoint(
                x: plan.sourcePoint.x + ((plan.targetPoint.x - plan.sourcePoint.x) * progress),
                y: plan.sourcePoint.y + ((plan.targetPoint.y - plan.sourcePoint.y) * progress)
            )
            postMouse(.leftMouseDragged, at: point, source: source, flags: plan.modifierFlags)
            await pause(plan.duration / TimeInterval(steps))
        }

        postMouse(.leftMouseUp, at: plan.targetPoint, source: source, flags: [])

        if restoreMousePosition {
            await pause(0.08)
            postMouseMove(to: currentMouse, source: source)
        }

        return true
    }

    private func postMouseMove(to point: CGPoint, source: CGEventSource) {
        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func postMouse(
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

    private func pause(_ interval: TimeInterval) async {
        guard interval.isFinite, interval > 0 else { return }
        let nanoseconds = UInt64((interval * 1_000_000_000).rounded())
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
