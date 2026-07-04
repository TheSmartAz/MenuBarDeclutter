import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HidingVisibilityState")
@MainActor
struct HidingVisibilityStateTests {
    @Test func separatorStateMappings() {
        // collapsed
        #expect(HidingVisibilityState.collapsed.primarySeparatorState == .collapsed)
        #expect(HidingVisibilityState.collapsed.alwaysHiddenSeparatorState == .collapsed)

        // expanded
        #expect(HidingVisibilityState.expanded.primarySeparatorState == .expanded)
        #expect(HidingVisibilityState.expanded.alwaysHiddenSeparatorState == .collapsed)

        // revealAll
        #expect(HidingVisibilityState.revealAll.primarySeparatorState == .expanded)
        #expect(HidingVisibilityState.revealAll.alwaysHiddenSeparatorState == .expanded)
    }

    @Test func collapsedAndRevealAllFlags() {
        #expect(HidingVisibilityState.collapsed.isCollapsed == true)
        #expect(HidingVisibilityState.collapsed.isRevealAll == false)
        #expect(HidingVisibilityState.revealAll.isCollapsed == false)
        #expect(HidingVisibilityState.revealAll.isRevealAll == true)
        #expect(HidingVisibilityState.expanded.isCollapsed == false)
        #expect(HidingVisibilityState.expanded.isRevealAll == false)
    }

    @Test func normalToggle() {
        #expect(HidingVisibilityState.collapsed.toggled == .expanded)
        #expect(HidingVisibilityState.expanded.toggled == .collapsed)
        #expect(HidingVisibilityState.revealAll.toggled == .collapsed)
    }

    @Test func optionToggle() {
        #expect(HidingVisibilityState.collapsed.optionToggled == .revealAll)
        #expect(HidingVisibilityState.expanded.optionToggled == .revealAll)
        #expect(HidingVisibilityState.revealAll.optionToggled == .collapsed)
    }

    @Test func allCasesAreThree() {
        #expect(HidingVisibilityState.allCases == [.collapsed, .expanded, .revealAll])
    }

    @Test func basicModeReadinessReportsReadyExpandedState() {
        let readiness = BasicModeReadiness.evaluate(
            visibilityState: .expanded,
            primarySeparatorLength: AppConstants.defaultExpandedSeparatorLength,
            alwaysHiddenEnabled: false,
            alwaysHiddenSeparatorInstalled: false,
            alwaysHiddenSeparatorLength: nil
        )

        #expect(readiness.status == .ready)
        #expect(readiness.tone == .ready)
        #expect(readiness.systemImage == "checkmark.shield")
    }

    @Test func basicModeReadinessWarnsWhenPrimarySeparatorIsMissing() {
        let readiness = BasicModeReadiness.evaluate(
            visibilityState: .expanded,
            primarySeparatorLength: 0,
            alwaysHiddenEnabled: false,
            alwaysHiddenSeparatorInstalled: false,
            alwaysHiddenSeparatorLength: nil
        )

        #expect(readiness.status == .primarySeparatorMissing)
        #expect(readiness.tone == .warning)
    }

    @Test func basicModeReadinessWarnsWhenCollapsedSeparatorIsStillShort() {
        let readiness = BasicModeReadiness.evaluate(
            visibilityState: .collapsed,
            primarySeparatorLength: AppConstants.defaultExpandedSeparatorLength,
            alwaysHiddenEnabled: false,
            alwaysHiddenSeparatorInstalled: false,
            alwaysHiddenSeparatorLength: nil
        )

        #expect(readiness.status == .primarySeparatorTooShortForCollapsedState)
        #expect(readiness.tone == .warning)
    }

    @Test func basicModeReadinessWarnsWhenAlwaysHiddenSeparatorIsMissing() {
        let readiness = BasicModeReadiness.evaluate(
            visibilityState: .expanded,
            primarySeparatorLength: AppConstants.defaultExpandedSeparatorLength,
            alwaysHiddenEnabled: true,
            alwaysHiddenSeparatorInstalled: false,
            alwaysHiddenSeparatorLength: nil
        )

        #expect(readiness.status == .alwaysHiddenSeparatorMissing)
        #expect(readiness.tone == .warning)
    }

    @Test func basicModeReadinessHandlesUnavailableRuntimeStatus() {
        let readiness = BasicModeReadiness.evaluate(
            visibilityState: nil,
            primarySeparatorLength: nil,
            alwaysHiddenEnabled: false,
            alwaysHiddenSeparatorInstalled: false,
            alwaysHiddenSeparatorLength: nil
        )

        #expect(readiness.status == .runtimeUnavailable)
        #expect(readiness.tone == .info)
    }
}
