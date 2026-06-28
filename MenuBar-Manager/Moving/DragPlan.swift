import CoreGraphics
import Foundation

struct DragPlan: Equatable, Sendable {
    let sourceFrame: CGRect
    let targetFrame: CGRect
    let sourcePoint: CGPoint
    let targetPoint: CGPoint
    let modifierFlags: CGEventFlags
    let duration: TimeInterval
    let retryCount: Int
    let preMoveVisibilityState: HidingVisibilityState
    let targetZone: MenuBarZone

    var summary: String {
        let source = "source \(Int(sourcePoint.x)),\(Int(sourcePoint.y))"
        let target = "target \(Int(targetPoint.x)),\(Int(targetPoint.y))"
        return "\(source) -> \(target), zone \(targetZone.displayName), retries \(retryCount)"
    }
}

struct DragPlanningContext: Equatable, Sendable {
    let primarySeparatorFrame: CGRect?
    let alwaysHiddenSeparatorFrame: CGRect?
    let screenFrame: CGRect

    init(
        primarySeparatorFrame: CGRect?,
        alwaysHiddenSeparatorFrame: CGRect?,
        screenFrame: CGRect = CGRect(x: 0, y: 0, width: 1440, height: 900)
    ) {
        self.primarySeparatorFrame = primarySeparatorFrame
        self.alwaysHiddenSeparatorFrame = alwaysHiddenSeparatorFrame
        self.screenFrame = screenFrame
    }
}

struct DragPlanFactory {
    func plan(
        for snapshot: MenuBarItemSnapshot,
        command: IconMoveCommand,
        context: DragPlanningContext,
        preMoveVisibilityState: HidingVisibilityState,
        duration: TimeInterval,
        retryCount: Int
    ) throws -> DragPlan {
        guard let sourceFrame = snapshot.frame else {
            throw IconMoveError.missingSourceFrame
        }

        let targetZone = command.targetZone(currentZone: snapshot.zone)
        let targetFrame = targetFrame(
            sourceFrame: sourceFrame,
            targetZone: targetZone,
            command: command,
            context: context
        )

        return DragPlan(
            sourceFrame: sourceFrame,
            targetFrame: targetFrame,
            sourcePoint: CGPoint(x: sourceFrame.midX, y: sourceFrame.midY),
            targetPoint: CGPoint(x: targetFrame.midX, y: targetFrame.midY),
            modifierFlags: .maskCommand,
            duration: duration,
            retryCount: retryCount,
            preMoveVisibilityState: preMoveVisibilityState,
            targetZone: targetZone
        )
    }

    private func targetFrame(
        sourceFrame: CGRect,
        targetZone: MenuBarZone,
        command: IconMoveCommand,
        context: DragPlanningContext
    ) -> CGRect {
        let spacing = max(sourceFrame.width * 1.5, 36)

        switch command {
        case .moveLeft:
            return clamped(sourceFrame.offsetBy(dx: -spacing, dy: 0), screenFrame: context.screenFrame)
        case .moveRight:
            return clamped(sourceFrame.offsetBy(dx: spacing, dy: 0), screenFrame: context.screenFrame)
        case .moveToZone:
            break
        }

        let x: CGFloat
        switch targetZone {
        case .visible:
            x = (context.primarySeparatorFrame?.maxX ?? sourceFrame.maxX) + spacing
        case .hidden:
            if let primary = context.primarySeparatorFrame,
               let alwaysHidden = context.alwaysHiddenSeparatorFrame {
                x = (primary.minX + alwaysHidden.maxX) / 2
            } else if let primary = context.primarySeparatorFrame {
                x = primary.minX - spacing
            } else {
                x = sourceFrame.midX - spacing
            }
        case .alwaysHidden:
            if let alwaysHidden = context.alwaysHiddenSeparatorFrame {
                x = alwaysHidden.minX - spacing
            } else if let primary = context.primarySeparatorFrame {
                x = primary.minX - (spacing * 2)
            } else {
                x = sourceFrame.midX - (spacing * 2)
            }
        case .unknown:
            x = sourceFrame.midX
        }

        var frame = sourceFrame
        frame.origin.x = x - (sourceFrame.width / 2)
        return clamped(frame, screenFrame: context.screenFrame)
    }

    private func clamped(_ frame: CGRect, screenFrame: CGRect) -> CGRect {
        var next = frame
        next.origin.x = min(max(next.minX, screenFrame.minX), screenFrame.maxX - next.width)
        next.origin.y = min(max(next.minY, screenFrame.minY), screenFrame.maxY - next.height)
        return next
    }
}
