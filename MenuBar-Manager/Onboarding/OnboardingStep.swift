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
    /// The ordered set of first-run onboarding steps introduced in Phase 3.
    /// These live as a static list so the order can be unit-tested and the
    /// content reviewed in one place.
    static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "intro",
            title: "Welcome to \(AppConstants.displayName)",
            symbol: "sparkles",
            body: "\(AppConstants.displayName) cleans up your menu bar by hiding icons you don't need right now. It works using only public macOS behavior — no Accessibility, Screen Recording, or other sensitive permissions."
        ),
        OnboardingStep(
            id: "commandDrag",
            title: "Command-drag the separator",
            symbol: "hand.point.up.left",
            body: "Hold Command (⌘) and drag the chevron separator to choose which icons are hidden. Items to the right of the separator disappear when the bar is collapsed."
        ),
        OnboardingStep(
            id: "hiddenVsAlwaysHidden",
            title: "Hidden vs Always-Hidden",
            symbol: "rectangle.split.2x1",
            body: "Normally hidden icons return when you expand the bar. Enable Always-Hidden in Settings to add a second separator; icons past it stay hidden even when the primary zone is expanded."
        ),
        OnboardingStep(
            id: "hotkeyAutoRehide",
            title: "Hotkey & Auto-Rehide",
            symbol: "rectangle.rightthird.inset.filled",
            body: "Toggle the bar with a global hotkey (Option+Command+B by default), and optionally let the bar collapse itself again after a few seconds with Auto-Rehide. The hotkey is off by default; Auto-Rehide is off by default and adjustable in Settings → Behavior."
        ),
        OnboardingStep(
            id: "privacy",
            title: "Privacy",
            symbol: "hand.raised",
            body: "Basic Mode never requests Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access. Pro-only capabilities, when they ship, will require explicit opt-in."
        ),
        OnboardingStep(
            id: "macOS26Note",
            title: "macOS 26 note",
            symbol: "rectangle.dashed",
            body: "On macOS 26 the transparent menu bar can make separators harder to see. You can toggle the separator visuals or adjust their appearance in Settings → Behavior.",
            callout: "Transparent menu bar visible."
        )
    ]
}
