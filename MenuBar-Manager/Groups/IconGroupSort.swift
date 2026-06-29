import Foundation

/// Sorts icon groups deterministically.
nonisolated struct IconGroupSort {
    /// Sort groups by sortOrder, then by name for stability.
    static func sort(_ groups: [IconGroup]) -> [IconGroup] {
        groups.sorted { a, b in
            if a.sortOrder != b.sortOrder {
                return a.sortOrder < b.sortOrder
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }
}
