import Testing
@testable import MenuBarDeclutter

@Suite("Separator Length Policy Logic")
struct SeparatorLengthPolicyLogicTests {
    @Test func mapsExpandedAndCollapsedLengths() {
        let policy = SeparatorLengthPolicy(
            expandedLength: 28,
            collapsedLengthOverride: nil,
            recommendedCollapsedLength: 4_000
        )

        #expect(policy.length(for: .expanded) == 28)
        #expect(policy.length(for: .collapsed) == 4_000)
    }

    @Test func positiveCollapsedOverrideWins() {
        let policy = SeparatorLengthPolicy(
            expandedLength: 28,
            collapsedLengthOverride: 1_500,
            recommendedCollapsedLength: 4_000
        )

        #expect(policy.collapsedLength == 1_500)
    }

    @Test func missingOrInvalidCollapsedOverrideUsesRecommendedLength() {
        let missing = SeparatorLengthPolicy(
            expandedLength: 28,
            collapsedLengthOverride: nil,
            recommendedCollapsedLength: 4_000
        )
        let zero = SeparatorLengthPolicy(
            expandedLength: 28,
            collapsedLengthOverride: 0,
            recommendedCollapsedLength: 4_000
        )
        let negative = SeparatorLengthPolicy(
            expandedLength: 28,
            collapsedLengthOverride: -12,
            recommendedCollapsedLength: 4_000
        )

        #expect(missing.collapsedLength == 4_000)
        #expect(zero.collapsedLength == 4_000)
        #expect(negative.collapsedLength == 4_000)
    }
}
