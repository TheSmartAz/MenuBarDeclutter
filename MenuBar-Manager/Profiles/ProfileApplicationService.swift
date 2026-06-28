import Foundation

struct ProfileMovePreview: Equatable, Sendable {
    let bundleIdentifier: String
    let displayName: String
    let currentZone: MenuBarZone
    let targetZone: MenuBarZone
}

struct ProfileApplicationDryRun: Equatable, Sendable {
    var itemsToReveal: [String]
    var itemsToMove: [ProfileMovePreview]
    var unavailableItems: [String]
    var permissionRequirements: [String]

    var isEmpty: Bool {
        itemsToReveal.isEmpty && itemsToMove.isEmpty && unavailableItems.isEmpty && permissionRequirements.isEmpty
    }

    var summary: String {
        if isEmpty {
            return "Profile can be applied without additional actions."
        }

        return "\(itemsToReveal.count) reveal actions, \(itemsToMove.count) move previews, \(unavailableItems.count) unavailable items, \(permissionRequirements.count) requirements."
    }
}

@MainActor
final class ProfileApplicationService {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let setVisibility: (HidingVisibilityState) -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        setVisibility: @escaping (HidingVisibilityState) -> Void
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.setVisibility = setVisibility
    }

    func dryRun(
        profile: ProfileModel,
        snapshots: [MenuBarItemSnapshot],
        accessibilityStatus: AccessibilityPermissionStatus,
        allowProMoves: Bool
    ) -> ProfileApplicationDryRun {
        var revealActions: [String] = []
        if profile.preferredVisibilityState == .expanded {
            revealActions.append("Expand hidden items")
        } else if profile.preferredVisibilityState == .revealAll {
            revealActions.append("Reveal all hidden items")
        }

        var movePreviews: [ProfileMovePreview] = []
        var unavailable: [String] = []

        for (bundleID, targetZone) in profile.targetZonesByBundleID.sorted(by: { $0.key < $1.key }) {
            guard let snapshot = snapshots.first(where: { $0.bundleIdentifier == bundleID }) else {
                unavailable.append(bundleID)
                continue
            }
            guard snapshot.zone != targetZone else { continue }

            movePreviews.append(ProfileMovePreview(
                bundleIdentifier: bundleID,
                displayName: displayName(for: snapshot),
                currentZone: snapshot.zone,
                targetZone: targetZone
            ))
        }

        var requirements: [String] = []
        if !movePreviews.isEmpty {
            if !settingsStore.proModeEnabled {
                requirements.append("Pro Mode must be enabled for zone moves.")
            }
            if accessibilityStatus != .granted {
                requirements.append("Accessibility permission is required to verify zone moves.")
            }
            if !allowProMoves {
                requirements.append("Zone moves require explicit confirmation and are not run by normal profile apply.")
            }
        }

        return ProfileApplicationDryRun(
            itemsToReveal: revealActions,
            itemsToMove: movePreviews,
            unavailableItems: unavailable,
            permissionRequirements: requirements
        )
    }

    @discardableResult
    func applyBasicSettings(
        profile: ProfileModel,
        snapshots: [MenuBarItemSnapshot],
        accessibilityStatus: AccessibilityPermissionStatus,
        allowProMoves: Bool = false
    ) -> ProfileApplicationDryRun {
        let summary = dryRun(
            profile: profile,
            snapshots: snapshots,
            accessibilityStatus: accessibilityStatus,
            allowProMoves: allowProMoves
        )

        settingsStore.secondBarEnabled = profile.showSecondBar
        settingsStore.autoRehideEnabled = profile.autoRehideEnabled
        settingsStore.hoverRevealEnabled = profile.hoverRevealEnabled
        setVisibility(profile.preferredVisibilityState)

        liveStatus.activeProfileID = profile.id.uuidString
        liveStatus.activeProfileName = profile.name
        liveStatus.lastProfileApplyLog = summary.summary
        diagnosticsLogger.log("Applied profile \(profile.name): \(summary.summary)")

        return summary
    }

    private func displayName(for snapshot: MenuBarItemSnapshot) -> String {
        [
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]
        .compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .first ?? "Menu Bar Item"
    }
}
