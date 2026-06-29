import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Profile Phase 11 Integration")
@MainActor
struct ProfilePhase11IntegrationTests {
    @Test func dryRunReportsGroupLayoutAndLabsChanges() {
        let harness = Harness()
        let groupID = UUID()
        let profile = ProfileModel(
            name: "Power",
            groupVisibilityPreferences: [groupID: true],
            protectedGroupIDs: [groupID],
            layoutModePreference: .fullMenuBar,
            fullMenuBarModePreference: true,
            spacingPresetPreference: "compact"
        )

        let dryRun = harness.service.dryRun(
            profile: profile,
            snapshots: [],
            accessibilityStatus: .notRequested,
            allowProMoves: false
        )

        #expect(dryRun.groupChanges.count == 1)
        #expect(dryRun.layoutChanges.contains("Enter Full Menu Bar Mode"))
        #expect(dryRun.labsChanges == ["Spacing preset: compact"])
        #expect(dryRun.permissionRequirements.contains("Spacing preset preference is blocked until Menu Bar Spacing Labs is enabled."))
    }

    @Test func applyCanEnterFullMenuBarModeAndApplyLabsWhenEnabled() {
        let harness = Harness()
        harness.store.menuBarSpacingLabsEnabled = true
        let profile = ProfileModel(
            name: "Layout",
            fullMenuBarModePreference: true,
            spacingPresetPreference: "dense"
        )

        _ = harness.service.applyBasicSettings(
            profile: profile,
            snapshots: [],
            accessibilityStatus: .notRequested
        )

        #expect(harness.enterFullModeCount == 1)
        #expect(harness.store.menuBarSpacingPreset == "dense")
    }

    private final class Harness {
        let store: SettingsStore
        let service: ProfileApplicationService
        let counter = CounterBox()

        var enterFullModeCount: Int {
            counter.value
        }

        init() {
            let suiteName = "ProfilePhase11IntegrationTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suiteName)!
            defaults.removePersistentDomain(forName: suiteName)
            store = SettingsStore(defaults: defaults)
            service = ProfileApplicationService(
                settingsStore: store,
                diagnosticsLogger: DiagnosticsLogger(),
                liveStatus: LiveDiagnosticsStatus(),
                setVisibility: { _ in },
                enterFullMenuBarMode: { [counter] in counter.value += 1 }
            )
        }
    }

    private final class CounterBox {
        var value = 0
    }
}
