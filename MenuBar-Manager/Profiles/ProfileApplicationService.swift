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
    var groupChanges: [String] = []
    var layoutChanges: [String] = []
    var protectedActions: [String] = []
    var labsChanges: [String] = []

    var isEmpty: Bool {
        itemsToReveal.isEmpty
            && itemsToMove.isEmpty
            && unavailableItems.isEmpty
            && permissionRequirements.isEmpty
            && groupChanges.isEmpty
            && layoutChanges.isEmpty
            && protectedActions.isEmpty
            && labsChanges.isEmpty
    }

    var summary: String {
        if isEmpty {
            return "Profile can be applied without additional actions."
        }

        return "\(itemsToReveal.count) reveal actions, \(itemsToMove.count) move previews, \(groupChanges.count) group changes, \(layoutChanges.count) layout changes, \(labsChanges.count) Labs changes, \(unavailableItems.count) unavailable items, \(permissionRequirements.count) requirements."
    }
}

@MainActor
final class ProfileApplicationService {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let liveStatus: LiveDiagnosticsStatus
    private let setVisibility: (HidingVisibilityState) -> Void
    private let enterFullMenuBarMode: () -> Void
    private let exitFullMenuBarMode: () -> Void
    private let refreshGroups: () -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        liveStatus: LiveDiagnosticsStatus,
        setVisibility: @escaping (HidingVisibilityState) -> Void,
        enterFullMenuBarMode: @escaping () -> Void = {},
        exitFullMenuBarMode: @escaping () -> Void = {},
        refreshGroups: @escaping () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.liveStatus = liveStatus
        self.setVisibility = setVisibility
        self.enterFullMenuBarMode = enterFullMenuBarMode
        self.exitFullMenuBarMode = exitFullMenuBarMode
        self.refreshGroups = refreshGroups
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
                requirements.append("Optional Pro must be enabled for zone moves.")
            }
            if accessibilityStatus != .granted {
                requirements.append("Accessibility permission is required to verify zone moves.")
            }
            if !allowProMoves {
                requirements.append("Zone moves require explicit confirmation and are not run by normal profile apply.")
            }
        }

        var groupChanges: [String] = []
        for (_, isVisible) in profile.groupVisibilityPreferences.sorted(by: { $0.key.uuidString < $1.key.uuidString }) {
            groupChanges.append(isVisible ? "Show group status item" : "Hide group status item")
        }

        var layoutChanges: [String] = []
        if profile.showSecondBar != settingsStore.secondBarEnabled {
            layoutChanges.append(profile.showSecondBar ? "Show Second Bar shortcut" : "Hide Second Bar shortcut")
        }
        if let layoutModePreference = profile.layoutModePreference {
            layoutChanges.append("Layout mode preference: \(layoutModePreference.displayName)")
        }
        if let fullMenuBarModePreference = profile.fullMenuBarModePreference {
            layoutChanges.append(fullMenuBarModePreference ? "Enter Full Menu Bar Mode" : "Exit Full Menu Bar Mode")
        }

        var protectedActions: [String] = []
        if !profile.protectedGroupIDs.isEmpty {
            protectedActions.append("\(profile.protectedGroupIDs.count) protected group preference(s)")
            if settingsStore.privateAccessEnabled && settingsStore.protectedGroupsRequireAuth {
                requirements.append("Private Access may be required for protected group changes.")
            }
        }

        var labsChanges: [String] = []
        if let spacingPresetPreference = profile.spacingPresetPreference {
            labsChanges.append("Spacing preset: \(spacingPresetPreference)")
            if !settingsStore.menuBarSpacingLabsEnabled {
                requirements.append("Spacing preset preference is blocked until Menu Bar Spacing Labs is enabled.")
            }
        }

        return ProfileApplicationDryRun(
            itemsToReveal: revealActions,
            itemsToMove: movePreviews,
            unavailableItems: unavailable,
            permissionRequirements: requirements,
            groupChanges: groupChanges,
            layoutChanges: layoutChanges,
            protectedActions: protectedActions,
            labsChanges: labsChanges
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

        settingsStore.autoRehideEnabled = profile.autoRehideEnabled
        settingsStore.hoverRevealEnabled = profile.hoverRevealEnabled
        settingsStore.secondBarEnabled = profile.showSecondBar
        setVisibility(profile.preferredVisibilityState)

        if let fullMenuBarModePreference = profile.fullMenuBarModePreference {
            if fullMenuBarModePreference {
                enterFullMenuBarMode()
            } else {
                exitFullMenuBarMode()
            }
        }

        if !profile.groupVisibilityPreferences.isEmpty {
            settingsStore.groupStatusItemsEnabled = profile.groupVisibilityPreferences.values.contains(true)
            refreshGroups()
        }

        if let spacingPresetPreference = profile.spacingPresetPreference,
           settingsStore.menuBarSpacingLabsEnabled {
            settingsStore.menuBarSpacingPreset = spacingPresetPreference
        }

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
