import Foundation

/// Canonical identity used to match a workspace's desired item to a live
/// `MenuBarItemSnapshot`. The same key must be derivable from a snapshot at any
/// position, because a workspace switch moves items around between scans.
///
/// It keys on `bundleIdentifier` (stable when the item moves) and deliberately
/// avoids `title` (which can be dynamic, e.g. a battery percentage) and the
/// snapshot `id` (which is derived from the frame and therefore changes on move).
///
/// Known limitation: an app that owns multiple status items collapses to one
/// key; disambiguating those is a later refinement.
nonisolated enum WorkspaceItemKey {
    static func key(for snapshot: MenuBarItemSnapshot) -> String {
        if let bundle = snapshot.bundleIdentifier, !bundle.isEmpty {
            return "bundle:" + bundle
        }
        if let app = snapshot.owningApplicationName, !app.isEmpty {
            return "app:" + app
        }
        return "id:" + snapshot.id
    }
}
