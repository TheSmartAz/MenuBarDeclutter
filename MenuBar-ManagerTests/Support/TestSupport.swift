import CoreGraphics
import Foundation
@testable import MenuBarDeclutter

/// Shared test support helpers for the MenuBarDeclutter unit-test target.
///
/// These tiny factories exist to remove boilerplate-duplication across test suites:
/// - `TestDefaults.makeIsolated()` and `TestDefaults.withIsolatedDefaults(...)` replace
///   inline `UserDefaults(suiteName:)` + `removePersistentDomain` setup blocks.
/// - `TestSnapshots.makeSnapshot()` unifies the 5 near-identical `MenuBarItemSnapshot`
///   factories re-implemented in `AccessibilityDiscoveryLogicTests`,
///   `IconMovePlanningTests`, `ProfileApplicationDryRunTests`, `SearchServiceTests`,
///   and `MenuBarScanCoordinatorTests`.
///
/// Each helper is intentionally minimal and uses sensible defaults that match the
/// conventions already established across the existing tests:
///   - role `"AXMenuBarItem"`, subrole `nil`
///   - frame `CGRect(x: 100, y: 40, width: 24, height: 22)`
///   - bundle identifier `com.example.app` (overridable)
///   - owning pid `42`, owning app name `"Example"`
///   - `isLikelySystemItem: false`, `zone: .visible`
///
/// The factories are `@MainActor`-isolated to match the app's default actor isolation
/// (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) and avoid carrying their own per-suite
/// `@MainActor` annotations.

enum TestDefaults {
    /// Returns a fresh, isolated `UserDefaults` instance with its persistent domain
    /// pre-cleared. Prefer `withIsolatedDefaults` when a test can keep setup and assertions
    /// inside one closure and should guarantee deterministic cleanup.
    static func makeIsolated() -> UserDefaults {
        let suiteName = "MenuBarDeclutterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Runs `body` with an isolated `UserDefaults` instance and guarantees its persistent
    /// domain is removed after `body` returns, even on throw. Use this in tests that do
    /// not need to keep the defaults alive after the assertion.
    ///
    /// The defaults are supplied without a hardcoded retention of their suite name; the
    /// caller passes `body` the same defaults and the helper remembers the suite name for
    /// the deferred `removePersistentDomain(...)` call.
    static func withIsolatedDefaults<T>(
        _ body: (UserDefaults) throws -> T
    ) rethrows -> T {
        let suiteName = "MenuBarDeclutterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        return try body(defaults)
    }
}

enum TestSnapshots {
    /// Constructs a `MenuBarItemSnapshot` with the conventional test defaults used across
    /// `AccessibilityDiscoveryLogicTests`, `IconMovePlanningTests`,
    /// `ProfileApplicationDryRunTests`, `SearchServiceTests`, and
    /// `MenuBarScanCoordinatorTests`. Any argument left at `nil` falls back to the
    /// canonical defaults for those tests.
    static func makeSnapshot(
        id: String? = nil,
        title: String? = "Status",
        role: String? = "AXMenuBarItem",
        subrole: String? = nil,
        frame: CGRect? = CGRect(x: 100, y: 40, width: 24, height: 22),
        owningProcessIdentifier: pid_t? = 42,
        owningApplicationName: String? = "Example",
        bundleIdentifier: String? = "com.example.app",
        zone: MenuBarZone = .visible,
        isLikelySystemItem: Bool = false,
        scanTimestamp: Date = Date(timeIntervalSince1970: 1)
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: title,
            role: role,
            subrole: subrole,
            frame: frame,
            owningProcessIdentifier: owningProcessIdentifier,
            owningApplicationName: owningApplicationName,
            bundleIdentifier: bundleIdentifier,
            zone: zone,
            isLikelySystemItem: isLikelySystemItem,
            scanTimestamp: scanTimestamp
        )
    }
}
