import SwiftUI

/// Shared settings row for sliders with optional endpoint labels and a
/// monospaced trailing value.
struct LabeledSlider: View {
    private let title: LocalizedStringKey
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let sliderLabel: LocalizedStringKey?
    private let minimumValueLabel: LocalizedStringKey?
    private let maximumValueLabel: LocalizedStringKey?
    private let sliderWidth: CGFloat
    private let valueLabelWidth: CGFloat?
    private let valueFractionLength: Int?

    init(
        _ title: LocalizedStringKey,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        sliderLabel: LocalizedStringKey? = nil,
        minimumValueLabel: LocalizedStringKey? = nil,
        maximumValueLabel: LocalizedStringKey? = nil,
        sliderWidth: CGFloat = 220,
        valueLabelWidth: CGFloat? = nil,
        valueFractionLength: Int? = nil
    ) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.sliderLabel = sliderLabel
        self.minimumValueLabel = minimumValueLabel
        self.maximumValueLabel = maximumValueLabel
        self.sliderWidth = sliderWidth
        self.valueLabelWidth = valueLabelWidth
        self.valueFractionLength = valueFractionLength
    }

    var body: some View {
        LabeledContent(title) {
            if valueLabelWidth != nil, valueFractionLength != nil {
                HStack {
                    slider
                    valueLabel
                }
            } else {
                slider
            }
        }
    }

    @ViewBuilder
    private var slider: some View {
        if let minimumValueLabel, let maximumValueLabel {
            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                sliderLabelView
            } minimumValueLabel: {
                Text(minimumValueLabel)
            } maximumValueLabel: {
                Text(maximumValueLabel)
            }
            .frame(width: sliderWidth)
        } else {
            Slider(
                value: $value,
                in: range,
                step: step
            ) {
                sliderLabelView
            }
            .frame(width: sliderWidth)
        }
    }

    @ViewBuilder
    private var sliderLabelView: some View {
        if let sliderLabel {
            Text(sliderLabel)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var valueLabel: some View {
        if let valueLabelWidth, let valueFractionLength {
            Text(value, format: .number.precision(.fractionLength(valueFractionLength)))
                .font(.system(.body, design: .monospaced))
                .frame(width: valueLabelWidth, alignment: .trailing)
        }
    }
}
