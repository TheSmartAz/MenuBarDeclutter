import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("OnboardingStep")
@MainActor
struct OnboardingStepTests {
    @Test func allStepsAreUniqueAndOrdered() {
        let steps = OnboardingStep.allSteps
        #expect(steps.count == 9)

        let ids = steps.map(\.id)
        #expect(Set(ids).count == ids.count)

        #expect(steps[0].id == "welcome")
        #expect(steps[1].id == "nativeCleanup")
        #expect(steps[2].id == "basicHideReveal")
        #expect(steps[3].id == "arrange")
        #expect(steps[4].id == "findRescue")
        #expect(steps[5].id == "workspaces")
        #expect(steps[6].id == "privacy")
        #expect(steps[7].id == "recovery")
        #expect(steps[8].id == "finish")
    }

    @Test func nativeCleanupStepExplainsAppleSettingsBoundary() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "nativeCleanup" })
        #expect(step.title == "Use Control Center first")
        #expect(step.body.contains("Control Center"))
        #expect(step.body.contains("third-party"))
        #expect(step.body.contains("complements Apple's settings"))
    }

    @Test func finishStepCarriesLocalSampleWorkspaceCallout() throws {
        let step = OnboardingStep.allSteps.first { $0.id == "finish" }
        let callout = try #require(step?.callout)
        #expect(callout.contains("local app-owned commands"))
        #expect(callout.contains("requests no permissions"))
    }

    @Test func privacyStepMentionsNoSensitivePermissions() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "privacy" })
        #expect(step.body.contains("Accessibility"))
        #expect(step.body.contains("Screen Recording"))
        #expect(step.body.contains("ScreenCaptureKit"))
        #expect(step.body.contains("Apple Events"))
        #expect(step.body.contains("Input Monitoring"))
        #expect(step.body.contains("network"))
        #expect(step.body.contains("Basic Mode does not request"))
        #expect(step.body.contains("never turns on silently"))
    }

    @Test func arrangeStepKeepsStableFlowPermissionFree() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "arrange" })
        #expect(step.body.contains("Collapse"))
        #expect(step.body.contains("Reveal All"))
        #expect(step.body.contains("Reset Layout"))
        #expect(step.body.contains("Command"))
    }

    @Test func workspaceStepExplainsPreviewBoundary() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "workspaces" })
        #expect(step.body.contains("Function Bar"))
        #expect(step.body.contains("Linked Groups"))
        #expect(step.body.contains("Info Strip"))
        #expect(step.body.contains("do not replace or control"))
    }

    @Test func recoveryStepMentionsSafeModeAndDiagnostics() throws {
        let step = try #require(OnboardingStep.allSteps.first { $0.id == "recovery" })
        #expect(step.body.contains("Safe Mode"))
        #expect(step.body.contains("Reset Layout"))
        #expect(step.body.contains("Reveal All"))
        #expect(step.body.contains("diagnostics export"))
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
