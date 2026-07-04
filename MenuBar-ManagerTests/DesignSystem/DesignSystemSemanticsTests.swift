import SwiftUI
import Testing
@testable import MenuBarDeclutter

@Suite("Design system semantics")
struct DesignSystemSemanticsTests {
    @Test func statusBadgeStylesMapToExpectedSemantics() {
        #expect(StatusBadge.Style.basicMode.defaultTitle == "Basic Mode")
        #expect(StatusBadge.Style.basicMode.defaultSubtitle == "Privacy Safe")
        #expect(StatusBadge.Style.basicMode.systemImage == "checkmark.shield")
        #expect(StatusBadge.Style.basicMode.tone == .privacySafe)
        #expect(StatusBadge.Style.basicMode.isProminent)

        #expect(StatusBadge.Style.proMode.defaultTitle == "Optional Pro")
        #expect(StatusBadge.Style.proMode.defaultSubtitle == "Opt-in")
        #expect(StatusBadge.Style.proMode.systemImage == "star")
        #expect(StatusBadge.Style.proMode.tone == .accent)

        #expect(StatusBadge.Style.accessibilityRequired.systemImage == "accessibility")
        #expect(StatusBadge.Style.accessibilityRequired.tone == .permissionRequired)
        #expect(StatusBadge.Style.experimental.tone == .experimental)
        #expect(StatusBadge.Style.actionNeeded.tone == .destructive)
    }

    @Test func featureStatusesMapToReleaseSemantics() {
        #expect(FeatureStatus.allCases.map(\.title) == [
            "Stable",
            "Preview",
            "Labs",
            "Labs",
            "Disabled",
            "Unavailable",
            "Deferred"
        ])

        #expect(FeatureStatus.stable.systemImage == "checkmark.seal")
        #expect(FeatureStatus.stable.tone == .privacySafe)
        #expect(FeatureStatus.stable.isReleaseCore)
        #expect(!FeatureStatus.preview.isReleaseCore)

        #expect(FeatureStatus.preview.tone == .accent)
        #expect(FeatureStatus.labs.tone == .experimental)
        #expect(FeatureStatus.experimental.tone == .experimental)
        #expect(FeatureStatus.unavailable.tone == .disabled)
        #expect(FeatureStatus.deferred.tone == .disabled)

        #expect(FeatureStatus.labs.requiresExplicitOptIn)
        #expect(FeatureStatus.experimental.requiresExplicitOptIn)
        #expect(!FeatureStatus.preview.requiresExplicitOptIn)
    }

    @Test func clearGlassBadgeStylesCanRepresentFeatureStatuses() {
        #expect(ClearGlassBadgeStyle(featureStatus: .stable).title == "Stable")
        #expect(ClearGlassBadgeStyle(featureStatus: .preview).systemImage == "sparkles")
        #expect(ClearGlassBadgeStyle(featureStatus: .labs).title == "Labs")
        #expect(ClearGlassBadgeStyle(featureStatus: .experimental).title == "Labs")
        #expect(ClearGlassBadgeStyle(featureStatus: .unavailable).title == "Unavailable")
        #expect(ClearGlassBadgeStyle(featureStatus: .disabled).title == "Unavailable")
        #expect(ClearGlassBadgeStyle(featureStatus: .deferred).title == "Deferred")
    }

    @Test func requirementStatusModelsPermissionBoundaries() {
        #expect(RequirementRow.Status.permissionBoundary(isSatisfied: true, isRequired: true) == .satisfied)
        #expect(RequirementRow.Status.permissionBoundary(isSatisfied: false, isRequired: true) == .required)
        #expect(RequirementRow.Status.permissionBoundary(isSatisfied: false, isRequired: false) == .optional)
        #expect(RequirementRow.Status.permissionBoundary(isSatisfied: true, isRequired: true, isAvailable: false) == .unavailable)

        #expect(RequirementRow.Status.satisfied.systemImage == "checkmark.circle.fill")
        #expect(RequirementRow.Status.required.tone == .permissionRequired)
        #expect(RequirementRow.Status.unavailable.tone == .disabled)
        #expect(RequirementRow.Status.required.isBlocking)
        #expect(!RequirementRow.Status.optional.isBlocking)
    }

    @Test func noticeKindsUseLimitedSemanticColorRoles() {
        #expect(NoticeBanner.Kind.privacy.systemImage == "hand.raised")
        #expect(NoticeBanner.Kind.privacy.tone == .privacySafe)
        #expect(NoticeBanner.Kind.success.tone == .privacySafe)
        #expect(NoticeBanner.Kind.warning.tone == .permissionRequired)
        #expect(NoticeBanner.Kind.destructive.tone == .destructive)
        #expect(NoticeBanner.Kind.info.accessibilityPrefix == "Information")
    }

    @Test func menuBarZonesHaveCompactBadgeDescriptors() {
        let visible = MenuBarZoneBadge.Descriptor.descriptor(for: .visible)
        #expect(visible.shortTitle == "V")
        #expect(visible.title == "Visible")
        #expect(visible.tone == .privacySafe)

        let hidden = MenuBarZoneBadge.Descriptor.descriptor(for: .hidden)
        #expect(hidden.shortTitle == "H")
        #expect(hidden.systemImage == "eye.slash")
        #expect(hidden.tone == .accent)

        let alwaysHidden = MenuBarZoneBadge.Descriptor.descriptor(for: .alwaysHidden)
        #expect(alwaysHidden.shortTitle == "A")
        #expect(alwaysHidden.tone == .destructive)

        let unknown = MenuBarZoneBadge.Descriptor.descriptor(for: .unknown)
        #expect(unknown.shortTitle == "?")
        #expect(unknown.tone == .disabled)
    }

    @Test func toolbarVariantsStaySemantic() {
        #expect(ToolbarButton.Variant.standard.tone == .neutral)
        #expect(ToolbarButton.Variant.selected.tone == .accent)
        #expect(ToolbarButton.Variant.destructive.tone == .destructive)
        #expect(ToolbarButton.Variant.selected.isProminent)
        #expect(!ToolbarButton.Variant.standard.isProminent)
    }

    @Test func unavailablePanelActionStylesExposeExpectedRoles() {
        #expect(UnavailablePanel.Action.Style.primary.role == nil)
        #expect(UnavailablePanel.Action.Style.secondary.role == nil)
        #expect(UnavailablePanel.Action.Style.destructive.role == .destructive)
        #expect(UnavailablePanel.Action.Style.primary.isProminent)
        #expect(!UnavailablePanel.Action.Style.secondary.isProminent)
    }
}
