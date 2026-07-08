import SwiftUI

/// A setup / requirement "step row": a `ClearGlassControlRow` whose trailing
/// accessory is a `ClearGlassStatusValue` with an optional caller-supplied
/// action beneath it, dimming when the step is not yet actionable.
///
/// Consolidates the shared accessory skeleton of `SearchRequirementRow`,
/// `ProSecondBarSetupStepRow`, and `FindRescueSetupStepRow`. The button styling
/// differs per caller (plain / prominent / with icon / disabled), so each passes
/// its own button via the `action` slot; the status value, trailing layout, and
/// dimming are shared here.
///
/// Not merged: `ArrangeStepRow` (badge accessory), `RequirementRow`
/// (self-contained Status enum), `DogfoodChecklistRow` (Picker row) — genuinely
/// different components.
struct ClearGlassStepRow<Action: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let iconTint: Color
    private let statusText: String
    private let statusStyle: ClearGlassStatusStyle
    private let isDimmed: Bool
    @ViewBuilder private let action: Action

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary,
        statusText: String,
        statusStyle: ClearGlassStatusStyle,
        isDimmed: Bool = false,
        @ViewBuilder action: () -> Action = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.isDimmed = isDimmed
        self.action = action()
    }

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint
        ) {
            VStack(alignment: .trailing, spacing: 8) {
                ClearGlassStatusValue(text: statusText, style: statusStyle)
                action
            }
        }
        .opacity(isDimmed ? 0.72 : 1)
    }
}
