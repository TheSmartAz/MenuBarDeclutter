import Foundation

/// Pure length decision used by Basic Mode separator hiding.
///
/// AppKit applies the resulting value to `NSStatusItem.length`; keeping the
/// decision isolated here makes the hide/reveal engine testable without
/// launching an app or installing status items.
struct SeparatorLengthPolicy: Equatable, Sendable {
    let expandedLength: Double
    let collapsedLengthOverride: Double?
    let recommendedCollapsedLength: Double

    var collapsedLength: Double {
        if let collapsedLengthOverride, collapsedLengthOverride > 0 {
            return collapsedLengthOverride
        }
        return recommendedCollapsedLength
    }

    func length(for state: HidingState) -> Double {
        switch state {
        case .expanded:
            return expandedLength
        case .collapsed:
            return collapsedLength
        }
    }
}
