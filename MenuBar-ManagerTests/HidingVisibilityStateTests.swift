import Foundation
import Testing
@testable import MenuBar_Manager

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
}
