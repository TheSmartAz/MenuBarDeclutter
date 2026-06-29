import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("OnboardingStep")
@MainActor
struct OnboardingStepTests {
    @Test func allStepsAreUniqueAndOrdered() {
        let steps = OnboardingStep.allSteps
        #expect(steps.count == 7)

        let ids = steps.map(\.id)
        #expect(Set(ids).count == ids.count)

        #expect(steps[0].id == "intro")
        #expect(steps[1].id == "nativeCleanup")
        #expect(steps[2].id == "commandDrag")
        #expect(steps[3].id == "hiddenVsAlwaysHidden")
        #expect(steps[4].id == "hotkeyAutoRehide")
        #expect(steps[5].id == "privacy")
        #expect(steps[6].id == "macOS26Note")
    }

    @Test func nativeCleanupStepExplainsAppleSettingsBoundary() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "nativeCleanup" })
        #expect(step.title == "Start with Apple's Menu Bar settings")
        #expect(step.body.contains("Control Center"))
        #expect(step.body.contains("third-party"))
        #expect(step.body.contains("complements Apple's settings"))
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

    @Test func nativeCleanupSettingsOpenerFallsBackToSystemSettings() {
        var openedURLs: [URL] = []

        let opened = OnboardingSystemSettingsOpener.openMenuBarSettings { url in
            openedURLs.append(url)
            return url == OnboardingSystemSettingsOpener.systemSettingsApplicationURL
        }

        #expect(opened)
        #expect(openedURLs == [
            OnboardingSystemSettingsOpener.menuBarSettingsURL,
            OnboardingSystemSettingsOpener.systemSettingsApplicationURL
        ])
    }

    @Test func nativeCleanupSettingsOpenerStopsAfterDeepLinkSuccess() {
        var openedURLs: [URL] = []

        let opened = OnboardingSystemSettingsOpener.openMenuBarSettings { url in
            openedURLs.append(url)
            return true
        }

        #expect(opened)
        #expect(openedURLs == [OnboardingSystemSettingsOpener.menuBarSettingsURL])
    }
}
