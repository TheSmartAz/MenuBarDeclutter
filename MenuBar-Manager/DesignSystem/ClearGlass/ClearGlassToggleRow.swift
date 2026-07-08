import SwiftUI

/// A `ClearGlassControlRow` whose accessory is a standard label-hidden switch.
///
/// Collapses the repeated settings idiom
/// `ClearGlassControlRow(...) { Toggle("…", isOn: $x).labelsHidden() }`
/// (~6 lines) into a single call. Delegates all row chrome to
/// `ClearGlassControlRow`, so appearance is unchanged.
struct ClearGlassToggleRow: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let iconTint: Color
    @Binding private var isOn: Bool
    private let onChange: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary,
        isOn: Binding<Bool>,
        onChange: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint
        self._isOn = isOn
        self.onChange = onChange
    }

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint
        ) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _, _ in onChange?() }
        }
    }
}
