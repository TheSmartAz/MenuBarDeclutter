import SwiftUI

struct SettingsScaffold<Sidebar: View, Content: View>: View {
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let content: Content

    init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        self.sidebar = sidebar()
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(minWidth: 180, idealWidth: 204, maxWidth: 240)
                .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                content
                    .padding(DesignTokens.Spacing.xLarge)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(.regularMaterial)
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}

struct SettingsSidebar<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(
        title: String = "Settings",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text(title)
                .font(DesignTokens.Typography.headline)
                .padding(.horizontal, DesignTokens.Spacing.xLarge)
                .padding(.top, DesignTokens.Spacing.xLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                content
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)

            Spacer(minLength: 0)
        }
    }
}

struct SettingsSidebarItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isEnabled: Bool
    let badgeTitle: String?
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        isSelected: Bool = false,
        isEnabled: Bool = true,
        badgeTitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.badgeTitle = badgeTitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Image(systemName: systemImage)
                    .frame(width: DesignTokens.IconSize.standard)

                Text(title)
                    .lineLimit(1)

                Spacer(minLength: DesignTokens.Spacing.medium)

                if let badgeTitle {
                    Text(badgeTitle)
                        .font(DesignTokens.Typography.caption.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.18), in: .rect(cornerRadius: 4))
                }
            }
            .font(DesignTokens.Typography.body)
            .padding(.horizontal, DesignTokens.Spacing.large)
            .padding(.vertical, DesignTokens.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(foregroundStyle)
            .background(backgroundStyle, in: .rect(cornerRadius: DesignTokens.Radius.control))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foregroundStyle: Color {
        if !isEnabled {
            return .secondary
        }

        return isSelected ? .white : .primary
    }

    private var backgroundStyle: Color {
        if isSelected {
            return .accentColor
        }

        if !isEnabled {
            return .secondary.opacity(0.08)
        }

        return .clear
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(DesignTokens.Typography.callout.bold())
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 0) {
                content
            }
            .background(.regularMaterial, in: .rect(cornerRadius: DesignTokens.Radius.group))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                    .strokeBorder(.secondary.opacity(0.18), lineWidth: DesignTokens.Stroke.hairline)
            }
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let title: String
    let detail: String?
    let systemImage: String?
    let isEnabled: Bool
    @ViewBuilder let trailing: Trailing

    init(
        title: String,
        detail: String? = nil,
        systemImage: String? = nil,
        isEnabled: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.large) {
            if let systemImage {
                Image(systemName: systemImage)
                    .frame(width: DesignTokens.IconSize.standard)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                if let detail {
                    Text(detail)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.large)

            trailing
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .opacity(isEnabled ? 1 : 0.72)
        .accessibilityElement(children: .combine)
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(
        title: String,
        detail: String? = nil,
        systemImage: String? = nil,
        isEnabled: Bool = true
    ) {
        self.init(
            title: title,
            detail: detail,
            systemImage: systemImage,
            isEnabled: isEnabled,
            trailing: { EmptyView() }
        )
    }
}
