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
            title: "Set up a quieter menu bar",
            symbol: "menubar.rectangle",
            body: "\(AppConstants.displayName) gives you a small native menu bar control for expanding and collapsing hidden icons. Basic Mode uses app-owned status items and public macOS behavior, without sensitive permissions."
        ),
        OnboardingStep(
            id: "nativeCleanup",
            title: "Use Control Center first",
            symbol: "switch.2",
            body: "Move rarely used system controls into Control Center first. Then use \(AppConstants.displayName) for third-party icons, separators, and crowded menu bar workflows. It complements Apple's settings rather than replacing them."
        ),
        OnboardingStep(
            id: "commandDrag",
            title: "Command-drag the separator",
            symbol: "hand.point.up.left",
            body: "Hold Command (⌘) and drag the separator in the menu bar to choose which icons are hidden. Items past the separator disappear when the bar is collapsed."
        ),
        OnboardingStep(
            id: "hiddenVsAlwaysHidden",
            title: "Hidden vs Always-Hidden",
            symbol: "rectangle.split.2x1",
            body: "Hidden icons come back when you expand the bar. Always-Hidden is optional: it adds a second separator for items that should stay tucked away even during a normal reveal."
        ),
        OnboardingStep(
            id: "hotkeyAutoRehide",
            title: "Hotkey & Auto-Rehide",
            symbol: "rectangle.rightthird.inset.filled",
            body: "You can enable a global hotkey, Option+Command+B by default, and optionally let the bar collapse itself again with Auto-Rehide. The hotkey is off by default; Auto-Rehide is off by default and adjustable in Settings → Behavior."
        ),
        OnboardingStep(
            id: "privacy",
            title: "Privacy",
            symbol: "hand.raised",
            body: "Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access. Pro features are opt-in and keep Basic Mode usable when permissions are missing."
        ),
        OnboardingStep(
            id: "macOS26Note",
            title: "macOS 26 note",
            symbol: "rectangle.dashed",
            body: "The transparent menu bar in macOS 26 can make separators harder to see on some wallpapers. Separator visuals stay adjustable without changing the Basic Mode permission boundary.",
            callout: "Use Settings → Behavior if a separator is too subtle on your wallpaper."
        )
    ]
}
