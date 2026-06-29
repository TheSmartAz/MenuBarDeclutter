import AppKit
import SwiftUI

struct PanelChrome<Content: View, Footer: View>: View {
    let title: String?
    let subtitle: String?
    let systemImage: String?
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    init(
        title: String? = nil,
        subtitle: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            if title != nil || subtitle != nil || systemImage != nil {
                PanelHeader(title: title, subtitle: subtitle, systemImage: systemImage)
                Divider()
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if Footer.self != EmptyView.self {
                Divider()
                footer
            }
        }
        .clearGlassSurface(cornerRadius: DesignTokens.Radius.panel, isProminent: true)
        .clipShape(.rect(cornerRadius: DesignTokens.Radius.panel))
    }
}

extension PanelChrome where Footer == EmptyView {
    init(
        title: String? = nil,
        subtitle: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            content: content,
            footer: { EmptyView() }
        )
    }
}

private struct PanelHeader: View {
    let title: String?
    let subtitle: String?
    let systemImage: String?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: DesignTokens.IconSize.standard, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                if let title {
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                        .lineLimit(1)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Spacing.xLarge)
        .padding(.vertical, DesignTokens.Spacing.large)
    }
}

struct SearchField: View {
    @Binding var text: String

    let placeholder: String
    let width: CGFloat?
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        width: CGFloat? = nil,
        onSubmit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        _text = text
        self.width = width
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(onSubmit)

            Button("Clear Search", systemImage: "xmark.circle.fill") {
                text = ""
                isFocused = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(text.isEmpty ? 0 : 1)
            .disabled(text.isEmpty)
            .help("Clear Search")
        }
        .font(DesignTokens.Typography.body)
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .frame(width: width)
        .background(.quaternary, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .strokeBorder(isFocused ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.16), lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
    }
}

struct ToolbarButton: View {
    enum Variant: String, CaseIterable, Sendable {
        case standard
        case selected
        case destructive

        var tone: DesignTokens.SemanticTone {
            switch self {
            case .standard:
                .neutral
            case .selected:
                .accent
            case .destructive:
                .destructive
            }
        }

        var isProminent: Bool {
            self == .selected
        }
    }

    enum LabelVisibility: String, Sendable {
        case iconOnly
        case iconAndTitle
    }

    let title: String
    let systemImage: String
    let variant: Variant
    let labelVisibility: LabelVisibility
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        variant: Variant = .standard,
        labelVisibility: LabelVisibility = .iconAndTitle,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.labelVisibility = labelVisibility
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: DesignTokens.IconSize.standard, weight: .medium))
                    .frame(width: 34, height: 24)
                    .background(variant.tone.backgroundStyle, in: .rect(cornerRadius: DesignTokens.Radius.control))
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                            .strokeBorder(variant.tone.borderStyle, lineWidth: DesignTokens.Stroke.hairline)
                    }

                if labelVisibility == .iconAndTitle {
                    Text(title)
                        .font(DesignTokens.Typography.caption)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 54)
            .foregroundStyle(variant.tone.foregroundStyle)
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
    }
}

struct AppIconView: View {
    let lookup: AppIconCache.Lookup
    let processIdentifier: pid_t?
    let size: CGFloat
    let cornerRadius: CGFloat

    private let iconCache: AppIconCache

    @State private var appIcon: NSImage

    @MainActor
    init(
        lookup: AppIconCache.Lookup,
        processIdentifier: pid_t? = nil,
        size: CGFloat = 28,
        cornerRadius: CGFloat? = nil,
        iconCache: AppIconCache = .shared
    ) {
        self.lookup = lookup
        self.processIdentifier = processIdentifier
        self.size = size
        self.cornerRadius = cornerRadius ?? min(DesignTokens.Radius.icon, size / 4)
        self.iconCache = iconCache
        _appIcon = State(initialValue: iconCache.cachedIcon(for: lookup) ?? iconCache.placeholderIcon)
    }

    @MainActor
    init(
        snapshot: MenuBarItemSnapshot,
        size: CGFloat = 28,
        cornerRadius: CGFloat? = nil,
        iconCache: AppIconCache = .shared
    ) {
        self.init(
            lookup: AppIconCache.Lookup(snapshot: snapshot),
            processIdentifier: snapshot.owningProcessIdentifier,
            size: size,
            cornerRadius: cornerRadius,
            iconCache: iconCache
        )
    }

    @MainActor
    init(
        bundleIdentifier: String?,
        applicationName: String?,
        filePath: String? = nil,
        processIdentifier: pid_t? = nil,
        size: CGFloat = 28,
        cornerRadius: CGFloat? = nil,
        iconCache: AppIconCache = .shared
    ) {
        self.init(
            lookup: AppIconCache.Lookup(
                bundleIdentifier: bundleIdentifier,
                applicationName: applicationName,
                filePath: filePath
            ),
            processIdentifier: processIdentifier,
            size: size,
            cornerRadius: cornerRadius,
            iconCache: iconCache
        )
    }

    var body: some View {
        Image(nsImage: appIcon)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.22), lineWidth: DesignTokens.Stroke.hairline)
            }
            .task(id: lookup) { @MainActor in
                let resolvedIcon = iconCache.icon(for: lookup, processIdentifier: processIdentifier)
                if appIcon !== resolvedIcon {
                    appIcon = resolvedIcon
                }
            }
    }
}
