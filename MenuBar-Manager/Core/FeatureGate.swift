import Foundation

/// Canonical runtime feature-availability predicates.
///
/// The "Optional Pro discovery is available" test —
/// `proModeEnabled && accessibilityDiscoveryEnabled` — was previously
/// copy-pasted across ~13 call sites (services, coordinators, and Settings
/// views). This type is the single source of truth so the Pro / Accessibility
/// policy changes in ONE place. The feature-rationalization record mandates
/// flipping this toward "Accessibility required to be useful"; that becomes a
/// one-line edit here instead of a 13-site sweep.
///
/// Distinct from `AssistedMoveGate`, which evaluates a full per-move context
/// (live permission grant, safe mode, per-item eligibility). `FeatureGate` is
/// only the coarse "has the user opted into Pro + Accessibility discovery?"
/// predicate; a live permission grant is still checked separately at the point
/// a real scan or move is attempted.
nonisolated enum FeatureGate {
    /// Whether Optional Pro Accessibility discovery is available: the user has
    /// opted into Pro Mode AND enabled Accessibility discovery.
    static func isProDiscoveryAvailable(
        proModeEnabled: Bool,
        accessibilityDiscoveryEnabled: Bool
    ) -> Bool {
        proModeEnabled && accessibilityDiscoveryEnabled
    }
}

extension SettingsStore {
    /// Whether Optional Pro Accessibility discovery is available for the current
    /// settings state. Canonical accessor for the ~11 call sites that previously
    /// inlined `proModeEnabled && accessibilityDiscoveryEnabled`.
    var isProDiscoveryAvailable: Bool {
        FeatureGate.isProDiscoveryAvailable(
            proModeEnabled: proModeEnabled,
            accessibilityDiscoveryEnabled: accessibilityDiscoveryEnabled
        )
    }
}
