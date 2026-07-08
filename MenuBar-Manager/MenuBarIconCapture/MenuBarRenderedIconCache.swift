import AppKit
import CoreGraphics
import Foundation

extension Notification.Name {
    static let menuBarRenderedIconCacheDidChange = Notification.Name("MBDMenuBarRenderedIconCacheDidChange")
}

@MainActor
final class MenuBarRenderedIconCache {
    static let shared = MenuBarRenderedIconCache()

    private var directoryURL: URL?
    private let fileManager: FileManager
    private let appearanceResolver: MenuBarIconAppearanceResolver
    private let notificationCenter: NotificationCenter
    private var imagesByKey: [MenuBarIconCacheKey: NSImage] = [:]
    private var latestKeyByIdentity: [String: MenuBarIconCacheKey] = [:]

    init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        appearanceResolver: MenuBarIconAppearanceResolver = MenuBarIconAppearanceResolver(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
        self.appearanceResolver = appearanceResolver
        self.notificationCenter = notificationCenter
    }

    func configure(directoryURL: URL?) {
        guard self.directoryURL != directoryURL else { return }
        self.directoryURL = directoryURL
        imagesByKey.removeAll()
        latestKeyByIdentity.removeAll()
        notificationCenter.post(name: .menuBarRenderedIconCacheDidChange, object: self)
    }

    func resolvedImage(for snapshot: MenuBarItemSnapshot) -> (image: NSImage, source: MenuBarIconSource)? {
        guard let key = appearanceResolver.cacheKey(for: snapshot) else {
            return nil
        }

        if let image = image(for: key) {
            return (image, .renderedCapture)
        }

        if let latestKey = latestKeyByIdentity[snapshot.id],
           let image = image(for: latestKey) {
            return (image, .staleRenderedCapture)
        }

        return nil
    }

    func cache(_ iconSnapshot: MenuBarIconSnapshot) {
        let image = NSImage(cgImage: iconSnapshot.image, size: iconSnapshot.frameInScreenPoints.size)
        imagesByKey[iconSnapshot.cacheKey] = image
        latestKeyByIdentity[iconSnapshot.identity.fingerprint] = iconSnapshot.cacheKey
        persistInBackground(cgImage: iconSnapshot.image, for: iconSnapshot.cacheKey)
        notificationCenter.post(
            name: .menuBarRenderedIconCacheDidChange,
            object: self,
            userInfo: ["identity": iconSnapshot.identity.fingerprint]
        )
    }

    @discardableResult
    func removeAll() -> Bool {
        imagesByKey.removeAll()
        latestKeyByIdentity.removeAll()

        guard let directoryURL else {
            notificationCenter.post(name: .menuBarRenderedIconCacheDidChange, object: self)
            return true
        }

        do {
            if fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.removeItem(at: directoryURL)
            }
            notificationCenter.post(name: .menuBarRenderedIconCacheDidChange, object: self)
            return true
        } catch {
            notificationCenter.post(name: .menuBarRenderedIconCacheDidChange, object: self)
            return false
        }
    }

    private func image(for key: MenuBarIconCacheKey) -> NSImage? {
        if let image = imagesByKey[key] {
            return image
        }

        guard let directoryURL else { return nil }
        let url = directoryURL.appendingPathComponent(key.storageFilename)
        guard let image = NSImage(contentsOf: url) else { return nil }
        imagesByKey[key] = image
        return image
    }

    /// Encodes the PNG and writes it to disk off the main actor. The in-memory
    /// cache and the change notification are already updated synchronously in
    /// `cache(_:)`, so callers see the new image immediately (they read the
    /// in-memory `imagesByKey`, never waiting on disk); only durable persistence
    /// is deferred. Previously this ran `pngData()` + atomic write per icon (up
    /// to 40 per sweep) synchronously on the main actor — a visible hitch. (H1)
    private func persistInBackground(cgImage: CGImage, for key: MenuBarIconCacheKey) {
        guard let directoryURL else { return }
        let url = directoryURL.appendingPathComponent(key.storageFilename)
        // `CGImage` is Sendable (immutable); `FileManager.default` is used
        // directly (thread-safe, no captured state) rather than the injected
        // instance, so both the encode and the write run off the main actor.
        Task.detached(priority: .utility) {
            guard let data = MenuBarRenderedIconCache.pngData(from: cgImage) else { return }
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            } catch {
                // The in-memory cache remains usable if disk persistence fails.
            }
        }
    }

    nonisolated private static func pngData(from cgImage: CGImage) -> Data? {
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }
}
