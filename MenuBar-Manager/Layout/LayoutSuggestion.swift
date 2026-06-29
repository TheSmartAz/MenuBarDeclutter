import Foundation

/// Kind of action a suggestion can trigger.
nonisolated enum LayoutSuggestionActionKind: String, CaseIterable, Sendable {
    case enableSecondBar
    case useFullMenuBarMode
    case addAlwaysHiddenZone
    case reduceAutoRehideAggressiveness
    case addSpacerDivider
    case compactSpacingLabs
    case disableHoverIfFlickering
    case resetSeparatorLength
    case enableProForBetterEstimate
    case runManualQAForDisplay
    case openLayoutSettings
    case openCrowdedRescue
}

/// Severity of a layout suggestion.
nonisolated enum LayoutSuggestionSeverity: String, CaseIterable, Sendable {
    case info
    case warning
    case critical
}

/// A non-invasive suggestion produced by ``LayoutSuggestionService``.
nonisolated struct LayoutSuggestion: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let severity: LayoutSuggestionSeverity
    let actionKind: LayoutSuggestionActionKind
    let isExperimental: Bool
    let requiresProMode: Bool
    let requiresAccessibility: Bool
    let requiresManualAction: Bool
    let createdAt: Date

    init(
        id: String,
        title: String,
        message: String,
        severity: LayoutSuggestionSeverity,
        actionKind: LayoutSuggestionActionKind,
        isExperimental: Bool = false,
        requiresProMode: Bool = false,
        requiresAccessibility: Bool = false,
        requiresManualAction: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.actionKind = actionKind
        self.isExperimental = isExperimental
        self.requiresProMode = requiresProMode
        self.requiresAccessibility = requiresAccessibility
        self.requiresManualAction = requiresManualAction
        self.createdAt = createdAt
    }
}
