import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("OnboardingStep")
@MainActor
struct OnboardingStepTests {
    @Test func allStepsAreUniqueAndOrdered() {
        let steps = OnboardingStep.allSteps
        #expect(steps.count == 6)

        let ids = steps.map(\.id)
        #expect(Set(ids).count == ids.count)

        #expect(steps[0].id == "intro")
        #expect(steps[1].id == "commandDrag")
        #expect(steps[2].id == "hiddenVsAlwaysHidden")
        #expect(steps[3].id == "hotkeyAutoRehide")
        #expect(steps[4].id == "privacy")
        #expect(steps[5].id == "macOS26Note")
    }

    @Test func macos26StepCarriesCallout() throws {
        let step = OnboardingStep.allSteps.first { $0.id == "macOS26Note" }
        let callout = try #require(step?.callout)
        #expect(!callout.isEmpty)
    }

    @Test func privacyStepMentionsNoSensitivePermissions() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "privacy" })
        #expect(step.body.contains("Accessibility"))
        #expect(step.body.contains("Screen Recording"))
        #expect(step.body.contains("network"))
    }

    @Test func behaviorStepMatchesCurrentDefaults() throws {
        let suiteName = "OnboardingStepTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "hotkeyAutoRehide" })

        #expect(store.globalHotkeyEnabled == false)
        #expect(store.autoRehideEnabled == false)
        #expect(step.body.contains("hotkey is off by default"))
        #expect(step.body.contains("Auto-Rehide is off by default"))
    }
}
