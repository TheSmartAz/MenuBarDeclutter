import Foundation

struct IconMoveConfirmationDecision: Equatable, Sendable {
    let confirmed: Bool
    let suppressFutureWarnings: Bool
}

struct IconMoveSafetyRules {
    func validate(
        snapshot: MenuBarItemSnapshot,
        allowSystemItems: Bool,
        appBundleIdentifier: String
    ) -> IconMoveError? {
        if isOwnItem(snapshot, appBundleIdentifier: appBundleIdentifier) {
            return .unsafeOwnItem
        }

        if snapshot.isLikelySystemItem && !allowSystemItems {
            return .unsafeSystemItem
        }

        if snapshot.frame == nil {
            return .missingSourceFrame
        }

        return nil
    }

    func isOwnItem(_ snapshot: MenuBarItemSnapshot, appBundleIdentifier: String) -> Bool {
        if snapshot.bundleIdentifier == appBundleIdentifier {
            return true
        }

        let title = (snapshot.title ?? "").localizedLowercase
        let appName = (snapshot.owningApplicationName ?? "").localizedLowercase
        return title.contains("menubardeclutter") || appName.contains("menubardeclutter")
    }
}
