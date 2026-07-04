import AppKit
import CoreGraphics
import Foundation

nonisolated enum MenuBarIconSource: String, Codable, Equatable, Sendable {
    case renderedCapture
    case staleRenderedCapture
    case bundleIconFallback
    case systemFallback
    case unknownFallback

    var displayName: String {
        switch self {
        case .renderedCapture:
            "Rendered"
        case .staleRenderedCapture:
            "Stale Rendered"
        case .bundleIconFallback:
            "App Icon"
        case .systemFallback:
            "System"
        case .unknownFallback:
            "Unknown"
        }
    }
}

nonisolated struct MenuBarIconIdentity: Hashable, Codable, Sendable {
    let fingerprint: String
    let bundleIdentifier: String?
    let ownerPID: pid_t?
    let ownerName: String?
    let axTitle: String?
    let axDescription: String?
    let zone: String

    init(snapshot: MenuBarItemSnapshot) {
        self.fingerprint = snapshot.id
        self.bundleIdentifier = snapshot.bundleIdentifier
        self.ownerPID = snapshot.owningProcessIdentifier
        self.ownerName = snapshot.owningApplicationName
        self.axTitle = snapshot.title
        self.axDescription = snapshot.role
        self.zone = snapshot.zone.rawValue
    }
}

nonisolated struct MenuBarIconCacheKey: Hashable, Codable, Sendable {
    let identityFingerprint: String
    let displayID: UInt32
    let backingScaleText: String
    let menuBarHeight: Int
    let appearanceName: String

    init(
        identityFingerprint: String,
        displayID: UInt32,
        backingScale: CGFloat,
        menuBarHeight: CGFloat,
        appearanceName: String
    ) {
        self.identityFingerprint = identityFingerprint
        self.displayID = displayID
        self.backingScaleText = String(format: "%.2f", Double(backingScale))
        self.menuBarHeight = Int(menuBarHeight.rounded())
        self.appearanceName = appearanceName
    }

    var storageFilename: String {
        "icon-\(Self.fnv1a64(storageSeed)).png"
    }

    private var storageSeed: String {
        [
            identityFingerprint,
            String(displayID),
            backingScaleText,
            String(menuBarHeight),
            appearanceName
        ].joined(separator: "|")
    }

    private static func fnv1a64(_ string: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return String(format: "%016llx", hash)
    }
}

nonisolated struct MenuBarIconSnapshot: Sendable {
    let identity: MenuBarIconIdentity
    let image: CGImage
    let frameInScreenPoints: CGRect
    let scale: CGFloat
    let cacheKey: MenuBarIconCacheKey
    let source: MenuBarIconSource
    let capturedAt: Date
}

@MainActor
struct MenuBarIconAppearanceResolver {
    func cacheKey(for snapshot: MenuBarItemSnapshot) -> MenuBarIconCacheKey? {
        guard let frame = snapshot.frame,
              let display = MenuBarDisplaySnapshot.bestMatch(for: frame) else {
            return nil
        }

        return MenuBarIconCacheKey(
            identityFingerprint: snapshot.id,
            displayID: display.displayID,
            backingScale: display.backingScale,
            menuBarHeight: frame.height,
            appearanceName: NSApp.effectiveAppearance.name.rawValue
        )
    }
}

nonisolated struct MenuBarDisplaySnapshot: Equatable, Sendable {
    let displayID: UInt32
    let frame: CGRect
    let backingScale: CGFloat

    @MainActor
    static func bestMatch(for frame: CGRect) -> MenuBarDisplaySnapshot? {
        let screens = NSScreen.screens
        let matchingScreen = screens.max { lhs, rhs in
            lhs.frame.intersection(frame).area < rhs.frame.intersection(frame).area
        } ?? NSScreen.main

        guard let screen = matchingScreen else { return nil }
        return MenuBarDisplaySnapshot(
            displayID: screen.displayIdentifier,
            frame: screen.frame,
            backingScale: screen.backingScaleFactor
        )
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite, width > 0, height > 0 else { return 0 }
        return width * height
    }
}

private extension NSScreen {
    var displayIdentifier: UInt32 {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}
