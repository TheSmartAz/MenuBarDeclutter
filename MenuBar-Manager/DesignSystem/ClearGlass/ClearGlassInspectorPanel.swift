import SwiftUI

/// Shared inspector-panel container: a titled card with a leading icon, an
/// optional subtitle, and a content slot, on the standard ClearGlass panel
/// background.
///
/// Consolidated from the byte-identical `AdvancedInspectorPanel` /
/// `LayoutInspectorPanel` private copies (cleanup wave 3). `MenuBarInspectorGroup`
/// is intentionally NOT merged here — it is a different, iconless grouping.
struct ClearGlassInspectorPanel<Content: View>: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var iconTint: Color = .secondary
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        iconTint: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(iconTint)
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.46), lineWidth: 0.5)
        }
    }
}
