import CoreGraphics
import Foundation

struct MenuBarItemSnapshot: Identifiable, Equatable, Sendable {
    let id: String
    let title: String?
    let role: String?
    let subrole: String?
    let frame: CGRect?
    let owningProcessIdentifier: pid_t?
    let owningApplicationName: String?
    let bundleIdentifier: String?
    let zone: MenuBarZone
    let isLikelySystemItem: Bool
    let scanTimestamp: Date

    init(
        id: String? = nil,
        title: String?,
        role: String?,
        subrole: String?,
        frame: CGRect?,
        owningProcessIdentifier: pid_t?,
        owningApplicationName: String?,
        bundleIdentifier: String?,
        zone: MenuBarZone,
        isLikelySystemItem: Bool,
        scanTimestamp: Date
    ) {
        self.title = title
        self.role = role
        self.subrole = subrole
        self.frame = frame
        self.owningProcessIdentifier = owningProcessIdentifier
        self.owningApplicationName = owningApplicationName
        self.bundleIdentifier = bundleIdentifier
        self.zone = zone
        self.isLikelySystemItem = isLikelySystemItem
        self.scanTimestamp = scanTimestamp
        self.id = id ?? Self.stableID(
            title: title,
            role: role,
            subrole: subrole,
            frame: frame,
            owningProcessIdentifier: owningProcessIdentifier,
            bundleIdentifier: bundleIdentifier
        )
    }

    static func stableID(
        title: String?,
        role: String?,
        subrole: String?,
        frame: CGRect?,
        owningProcessIdentifier: pid_t?,
        bundleIdentifier: String?
    ) -> String {
        let ownerComponent: String
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            ownerComponent = "bundle:\(bundleIdentifier)"
        } else {
            ownerComponent = owningProcessIdentifier.map { "pid:\($0)" } ?? "owner:nil"
        }

        let components = [
            ownerComponent,
            role ?? "role:nil",
            subrole ?? "subrole:nil",
            title ?? "title:nil",
            roundedFrameDescription(frame)
        ]
        return "mbd-\(fnv1a64(components.joined(separator: "|")))"
    }

    private static func roundedFrameDescription(_ frame: CGRect?) -> String {
        guard let frame else { return "frame:nil" }
        let values = [
            Int(frame.origin.x.rounded()),
            Int(frame.origin.y.rounded()),
            Int(frame.size.width.rounded()),
            Int(frame.size.height.rounded())
        ]
        return "frame:\(values.map(String.init).joined(separator: ","))"
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
