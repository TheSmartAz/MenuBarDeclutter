import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

@MainActor
final class MenuBarVisibleIconCapturer {
    private let appearanceResolver: MenuBarIconAppearanceResolver
    private let now: () -> Date

    init(
        appearanceResolver: MenuBarIconAppearanceResolver = MenuBarIconAppearanceResolver(),
        now: @escaping () -> Date = { Date() }
    ) {
        self.appearanceResolver = appearanceResolver
        self.now = now
    }

    func captureVisibleIcons(
        snapshots: [MenuBarItemSnapshot],
        maximumItems: Int = 40
    ) async -> [MenuBarIconSnapshot] {
        var captured: [MenuBarIconSnapshot] = []
        for snapshot in snapshots.prefix(maximumItems) {
            guard let iconSnapshot = await capture(snapshot) else { continue }
            captured.append(iconSnapshot)
        }
        return captured
    }

    private func capture(_ snapshot: MenuBarItemSnapshot) async -> MenuBarIconSnapshot? {
        guard let frame = sanitizedCaptureFrame(snapshot.frame),
              let cacheKey = appearanceResolver.cacheKey(for: snapshot) else {
            return nil
        }

        do {
            let image = try await captureImage(in: frame)
            return MenuBarIconSnapshot(
                identity: MenuBarIconIdentity(snapshot: snapshot),
                image: image,
                frameInScreenPoints: frame,
                scale: CGFloat(image.width) / max(frame.width, 1),
                cacheKey: cacheKey,
                source: .renderedCapture,
                capturedAt: now()
            )
        } catch {
            return nil
        }
    }

    private func sanitizedCaptureFrame(_ frame: CGRect?) -> CGRect? {
        guard var frame,
              frame.isNull == false,
              frame.isInfinite == false,
              frame.width >= 4,
              frame.height >= 4 else {
            return nil
        }

        frame.origin.x = frame.origin.x.rounded(.down)
        frame.origin.y = frame.origin.y.rounded(.down)
        frame.size.width = min(max(frame.width.rounded(.up), 4), 160)
        frame.size.height = min(max(frame.height.rounded(.up), 4), 48)
        return frame
    }

    private func captureImage(in rect: CGRect) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            SCScreenshotManager.captureImage(in: rect) { image, error in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? MenuBarVisibleIconCaptureError.captureFailed)
                }
            }
        }
    }
}

private enum MenuBarVisibleIconCaptureError: Error {
    case captureFailed
}
