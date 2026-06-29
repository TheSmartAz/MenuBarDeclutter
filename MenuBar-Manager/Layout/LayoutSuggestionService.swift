import Foundation

/// Translates capacity estimates and current settings into useful,
/// non-invasive suggestions.
///
/// Suggestions never silently enable Pro Mode or change global spacing.
nonisolated struct LayoutSuggestionService {
    var now: () -> Date = { Date() }

    /// Generate suggestions from the given capacity estimate and settings.
    func generate(
        estimate: LayoutCapacityEstimate,
        settings: LayoutSettings,
        proModeEnabled: Bool,
        secondBarEnabled: Bool,
        separatorLengthExtreme: Bool,
        manyHiddenItems: Bool
    ) -> [LayoutSuggestion] {
        var suggestions: [LayoutSuggestion] = []
        let timestamp = now()

        if estimate.isLikelyCrowded {
            if !secondBarEnabled {
                suggestions.append(
                    LayoutSuggestion(
                        id: "enable-second-bar",
                        title: "Enable Second Bar",
                        message: "Your menu bar appears crowded. Second Bar can show hidden items in a separate window.",
                        severity: .warning,
                        actionKind: .enableSecondBar,
                        createdAt: timestamp
                    )
                )
            }

            suggestions.append(
                LayoutSuggestion(
                    id: "use-full-menu-bar-mode",
                    title: "Use Full Menu Bar Mode",
                    message: "Temporarily reveal all items to access crowded icons. Full Menu Bar Mode suspends auto-rehide.",
                    severity: .info,
                    actionKind: .useFullMenuBarMode,
                    createdAt: timestamp
                )
            )
        }

        if estimate.isLikelyNotchConstrained {
            suggestions.append(
                LayoutSuggestion(
                    id: "notch-second-bar",
                    title: "Consider Second Bar for Notch Displays",
                    message: estimate.warnings.first(where: { $0 == .notchConstrained })?.message ?? "Second Bar is recommended for notch displays.",
                    severity: .info,
                    actionKind: .enableSecondBar,
                    createdAt: timestamp
                )
            )
        }

        if !proModeEnabled && estimate.source == .basicGeometryOnly {
            suggestions.append(
                LayoutSuggestion(
                    id: "enable-pro-better-estimate",
                    title: "Enable Pro Mode for Better Estimate",
                    message: "Pro Mode with Accessibility provides more accurate capacity estimates. It is optional and opt-in.",
                    severity: .info,
                    actionKind: .enableProForBetterEstimate,
                    requiresProMode: true,
                    requiresAccessibility: true,
                    requiresManualAction: true,
                    createdAt: timestamp
                )
            )
        }

        if separatorLengthExtreme {
            suggestions.append(
                LayoutSuggestion(
                    id: "reset-separator-length",
                    title: "Reset Separator Length",
                    message: "Your separator length appears unusual. Resetting it may improve layout behavior.",
                    severity: .warning,
                    actionKind: .resetSeparatorLength,
                    createdAt: timestamp
                )
            )
        }

        if manyHiddenItems {
            suggestions.append(
                LayoutSuggestion(
                    id: "add-spacer-divider",
                    title: "Add Spacer or Divider",
                    message: "Spacers and dividers can help organize a crowded menu bar.",
                    severity: .info,
                    actionKind: .addSpacerDivider,
                    createdAt: timestamp
                )
            )
        }

        if estimate.isLikelyCrowded && settings.menuBarSpacingLabsEnabled == false {
            suggestions.append(
                LayoutSuggestion(
                    id: "compact-spacing-labs",
                    title: "Try Compact Spacing (Labs)",
                    message: "Experimental compact spacing may help fit more items. It is reversible and Labs-only.",
                    severity: .info,
                    actionKind: .compactSpacingLabs,
                    isExperimental: true,
                    requiresManualAction: true,
                    createdAt: timestamp
                )
            )
        }

        if estimate.warnings.contains(.staleAXSnapshot) {
            suggestions.append(
                LayoutSuggestion(
                    id: "stale-ax-snapshot",
                    title: "Refresh Menu Bar Scan",
                    message: "The Accessibility snapshot is stale. Refresh it for a more accurate capacity estimate.",
                    severity: .info,
                    actionKind: .runManualQAForDisplay,
                    requiresProMode: true,
                    requiresAccessibility: true,
                    createdAt: timestamp
                )
            )
        }

        return suggestions
    }
}
