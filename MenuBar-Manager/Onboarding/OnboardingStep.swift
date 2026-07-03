import SwiftUI

/// Pure value type describing a single onboarding step. Kept free of AppKit
/// and side effects so it can be unit-tested and reused by previews.
struct OnboardingStep: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let symbol: String
    let body: String
    /// Optional callout used for macOS 26-specific notes.
    let callout: String?

    init(id: String, title: String, symbol: String, body: String, callout: String? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.body = body
        self.callout = callout
    }
}

extension OnboardingStep {
    /// The ordered set of first-run onboarding steps for the v0.1.9 product story.
    /// These live as a static list so the order can be unit-tested and the
    /// content reviewed in one place.
    static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "welcome",
            title: "Quiet your menu bar",
            symbol: "menubar.rectangle",
            body: "\(AppConstants.displayName) is a privacy-first menu bar declutter and Workspace tool. Basic Mode starts with native app-owned controls, local settings, and no sensitive permissions."
        ),
        OnboardingStep(
            id: "nativeCleanup",
            title: "Use Control Center first",
            symbol: "switch.2",
            body: "Move rarely used system controls into Control Center first. Then use \(AppConstants.displayName) for third-party icons, separators, and crowded menu bar workflows. It complements Apple's settings rather than replacing them."
        ),
        OnboardingStep(
            id: "basicHideReveal",
            title: "Basic Hide & Reveal",
            symbol: "eye",
            body: "The menu bar control and separator mark what hides and what returns. Collapse hides items past the separator; Expand and Reveal All bring them back without Pro Mode."
        ),
        OnboardingStep(
            id: "arrange",
            title: "Arrange with Command-drag",
            symbol: "hand.point.up.left",
            body: "Hold Command (⌘) and drag the control item and separator into reachable positions. Use Arrange to test Collapse, Reveal All, and Reset Layout."
        ),
        OnboardingStep(
            id: "findRescue",
            title: "Find & Rescue",
            symbol: "lifepreserver",
            body: "Find Icon, Second Bar, and New Item Inbox help recover hidden or newly discovered items. These Preview workflows use Pro Discovery only after explicit opt-in."
        ),
        OnboardingStep(
            id: "workspaces",
            title: "Workspaces Preview",
            symbol: "rectangle.3.group",
            body: "Workspaces organize app-owned Function Bar, Linked Groups, and Info Strip previews for different contexts. They do not replace or control the macOS system menu bar."
        ),
        OnboardingStep(
            id: "privacy",
            title: "Privacy Boundary",
            symbol: "hand.raised",
            body: "Basic Mode does not request Accessibility, Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, or network access. Pro Discovery is optional and never turns on silently."
        ),
        OnboardingStep(
            id: "recovery",
            title: "Recovery stays nearby",
            symbol: "cross.case",
            body: "Recovery keeps Safe Mode, Reset Layout, Reveal All, and diagnostics export reachable when optional Preview features or layout choices get confusing."
        ),
        OnboardingStep(
            id: "finish",
            title: "Choose your next step",
            symbol: "checkmark.circle",
            body: "Open Settings, test Arrange, create a first local Workspace, or skip advanced setup. Preview, Labs, Experimental, and Pro features remain off until you explicitly enable them.",
            callout: "Creating a sample Workspace uses local app-owned commands only and requests no permissions."
        )
    ]
}
