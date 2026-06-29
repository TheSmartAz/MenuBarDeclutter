import Foundation

/// Detects conflicts between hotkey bindings.
nonisolated struct HotkeyConflictDetector {
    /// Find all pairs of bindings that conflict (same key + modifiers).
    static func detectConflicts(in bindings: [HotkeyBinding]) -> [(HotkeyBinding, HotkeyBinding)] {
        var conflicts: [(HotkeyBinding, HotkeyBinding)] = []
        for i in 0..<bindings.count {
            for j in (i+1)..<bindings.count {
                if bindings[i].conflicts(with: bindings[j]) {
                    conflicts.append((bindings[i], bindings[j]))
                }
            }
        }
        return conflicts
    }

    /// Check if a new binding would conflict with existing bindings.
    static func wouldConflict(_ newBinding: HotkeyBinding, in bindings: [HotkeyBinding]) -> Bool {
        bindings.contains { $0.id != newBinding.id && $0.conflicts(with: newBinding) }
    }

    /// Count of conflicts.
    static func conflictCount(in bindings: [HotkeyBinding]) -> Int {
        detectConflicts(in: bindings).count
    }
}
