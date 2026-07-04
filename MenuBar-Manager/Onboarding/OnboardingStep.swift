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
    /// The ordered set of first-run onboarding steps for the v0.1.10 product story.
    /// These live as a static list so the order can be unit-tested and the
    /// content reviewed in one place.
    static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "welcome",
            title: "Quiet your menu bar",
            symbol: "menubar.rectangle",
            body: "\(AppConstants.displayName) starts in Basic Mode: local settings, app-owned controls, and no sensitive permissions. You can hide clutter first and decide later whether any Optional Pro tools are worth enabling."
        ),
        OnboardingStep(
            id: "nativeCleanup",
            title: "Use Control Center first",
            symbol: "switch.2",
            body: "Move rarely used system controls into Control Center first. Then use \(AppConstants.displayName) for third-party icons and separator-based cleanup. It complements Apple's settings rather than replacing them."
        ),
        OnboardingStep(
            id: "basicHideReveal",
            title: "Basic Hide & Reveal",
            symbol: "eye",
            body: "Place the control and separator, then collapse the items to the right of the separator. Expand or Reveal All brings them back in Basic Mode, without Accessibility, Screen Recording, or Optional Pro."
        ),
        OnboardingStep(
            id: "arrange",
            title: "Arrange with Command-drag",
            symbol: "hand.point.up.left",
            body: "Hold Command (⌘) and drag the control item and separator into reachable positions. Use Arrange to test Collapse, Reveal All, and Reset Layout."
        ),
        OnboardingStep(
            id: "findRescue",
            title: "Optional rescue tools",
            symbol: "lifepreserver",
            body: "Later, Find Icon, Second Bar, and New Item Inbox can help recover hidden or newly discovered items. They stay optional and use Optional Pro Discovery only after explicit opt-in."
        ),
        OnboardingStep(
            id: "workspaces",
            title: "Workspaces are app-owned",
            symbol: "rectangle.3.group",
            body: "Workspaces organize local Function Bar, Linked Groups, and Info Strip previews for different contexts. They are app-owned views and do not replace, capture, or control the macOS system menu bar."
        ),
        OnboardingStep(
            id: "privacy",
            title: "Privacy boundary",
            symbol: "hand.raised",
            body: "Basic Mode does not request Accessibility, Screen Recording, screen capture APIs, Apple Events, Input Monitoring, or network access. Optional Pro Discovery is separate, explicit, and never turns on silently."
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
            body: "Open Settings, test Arrange, create a local sample Workspace, or skip advanced setup. Preview, Labs, and Optional Pro features remain off until you explicitly enable them.",
            callout: "Creating a sample Workspace uses local app-owned commands only and requests no permissions."
        )
    ]
}
