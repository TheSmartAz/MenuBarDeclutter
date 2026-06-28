import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppIconCache {
    struct Lookup: Hashable, Sendable {
        let bundleIdentifier: String?
        let applicationName: String?
        let filePath: String?

        init(
            bundleIdentifier: String?,
            applicationName: String?,
            filePath: String? = nil
        ) {
            self.bundleIdentifier = Self.normalized(bundleIdentifier)
            self.applicationName = Self.normalized(applicationName)
            self.filePath = Self.normalized(filePath)
        }

        init(snapshot: MenuBarItemSnapshot) {
            self.init(
                bundleIdentifier: snapshot.bundleIdentifier,
                applicationName: snapshot.owningApplicationName
            )
        }

        var cacheKeys: [CacheKey] {
            var keys: [CacheKey] = []

            if let filePath {
                keys.append(.filePath(filePath))
            }

            if let bundleIdentifier {
                keys.append(.bundleIdentifier(bundleIdentifier))
            }

            if keys.isEmpty, let applicationName {
                keys.append(.applicationName(applicationName))
            }

            return keys
        }

        private static func normalized(_ value: String?) -> String? {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
    }

    static let shared = AppIconCache()

    let placeholderIcon: NSImage

    private var iconsByKey: [CacheKey: NSImage] = [:]

    init(placeholderIcon: NSImage = NSWorkspace.shared.icon(for: .application)) {
        self.placeholderIcon = placeholderIcon
    }

    func cachedIcon(for snapshot: MenuBarItemSnapshot) -> NSImage? {
        cachedIcon(for: Lookup(snapshot: snapshot))
    }

    func cachedIcon(for lookup: Lookup) -> NSImage? {
        lookup.cacheKeys.lazy.compactMap { self.iconsByKey[$0] }.first
    }

    func icon(for snapshot: MenuBarItemSnapshot) -> NSImage {
        icon(
            for: Lookup(snapshot: snapshot),
            processIdentifier: snapshot.owningProcessIdentifier
        )
    }

    func icon(for lookup: Lookup, processIdentifier: pid_t? = nil) -> NSImage {
        if let cachedIcon = cachedIcon(for: lookup) {
            return cachedIcon
        }

        let resolvedIcon = resolveIcon(for: lookup, processIdentifier: processIdentifier)
        cache(resolvedIcon, for: lookup.cacheKeys)
        return resolvedIcon
    }

    func removeAll() {
        iconsByKey.removeAll()
    }

    private func resolveIcon(for lookup: Lookup, processIdentifier: pid_t?) -> NSImage {
        if let processIdentifier,
           let icon = NSRunningApplication(processIdentifier: processIdentifier)?.icon {
            return icon
        }

        if let filePath = lookup.filePath {
            return NSWorkspace.shared.icon(forFile: filePath)
        }

        if let bundleIdentifier = lookup.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            cache(icon, for: [.filePath(appURL.path)])
            return icon
        }

        return placeholderIcon
    }

    private func cache(_ icon: NSImage, for keys: [CacheKey]) {
        for key in keys {
            iconsByKey[key] = icon
        }
    }
}

extension AppIconCache {
    enum CacheKey: Hashable, Sendable {
        case bundleIdentifier(String)
        case applicationName(String)
        case filePath(String)
    }
}
