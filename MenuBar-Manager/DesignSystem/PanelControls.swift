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
    let autoFocus: Bool
    let isEnabled: Bool
    let accessibilityIdentifier: String
    let clearAccessibilityIdentifier: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        width: CGFloat? = nil,
        autoFocus: Bool = false,
        isEnabled: Bool = true,
        accessibilityIdentifier: String = "",
        clearAccessibilityIdentifier: String = "",
        onSubmit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        _text = text
        self.width = width
        self.autoFocus = autoFocus
        self.isEnabled = isEnabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.clearAccessibilityIdentifier = clearAccessibilityIdentifier
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .disabled(!isEnabled)
                .onSubmit(onSubmit)
                .accessibilityLabel(placeholder)
                .accessibilityIdentifier(accessibilityIdentifier)

            Button("Clear Search", systemImage: "xmark.circle.fill") {
                text = ""
                isFocused = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(text.isEmpty ? 0 : 1)
            .disabled(text.isEmpty || !isEnabled)
            .help("Clear Search")
            .accessibilityIdentifier(clearAccessibilityIdentifier)
        }
        .font(DesignTokens.Typography.body)
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .background(.quaternary, in: .rect(cornerRadius: DesignTokens.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .strokeBorder(isFocused ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.16), lineWidth: DesignTokens.Stroke.hairline)
        }
        .opacity(isEnabled ? 1 : 0.72)
        .task {
            if autoFocus && isEnabled {
                isFocused = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct IntegratedSearchField: View {
    @Binding var text: String

    let placeholder: String
    let font: Font
    let autoFocus: Bool
    let isEnabled: Bool
    let accessibilityIdentifier: String
    let clearAccessibilityIdentifier: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        font: Font = .system(size: 18, weight: .regular),
        autoFocus: Bool = false,
        isEnabled: Bool = true,
        accessibilityIdentifier: String = "",
        clearAccessibilityIdentifier: String = "",
        onSubmit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        _text = text
        self.font = font
        self.autoFocus = autoFocus
        self.isEnabled = isEnabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.clearAccessibilityIdentifier = clearAccessibilityIdentifier
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(font)
                .focused($isFocused)
                .disabled(!isEnabled)
                .onSubmit(onSubmit)
                .accessibilityLabel(placeholder)
                .accessibilityIdentifier(accessibilityIdentifier)

            Button("Clear Search", systemImage: "xmark.circle.fill") {
                text = ""
                isFocused = true
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(text.isEmpty ? 0 : 1)
            .disabled(text.isEmpty || !isEnabled)
            .help("Clear Search")
            .accessibilityIdentifier(clearAccessibilityIdentifier)
        }
        .opacity(isEnabled ? 1 : 0.62)
        .frame(minHeight: 28)
        .contentShape(.rect)
        .onTapGesture {
            if isEnabled {
                isFocused = true
            }
        }
        .task {
            if autoFocus && isEnabled {
                isFocused = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct FloatingPanelToolbarBadge: View {
    let title: String
    let systemImage: String
    let tint: Color
    let accessibilityLabel: String

    init(
        _ title: String,
        systemImage: String,
        tint: Color = .secondary,
        accessibilityLabel: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.accessibilityLabel = accessibilityLabel ?? title
    }

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .bold()
            .lineLimit(1)
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.74), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: DesignTokens.Stroke.hairline)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }
}

struct FloatingPanelFooter: View {
    let leadingTitle: String
    let leadingSystemImage: String?
    let message: String?
    let emphasizedMessage: String?
    let trailingTitle: String?
    let trailingSystemImage: String?
    let trailingTint: Color

    init(
        leadingTitle: String,
        leadingSystemImage: String? = nil,
        message: String? = nil,
        emphasizedMessage: String? = nil,
        trailingTitle: String? = nil,
        trailingSystemImage: String? = nil,
        trailingTint: Color = .secondary
    ) {
        self.leadingTitle = leadingTitle
        self.leadingSystemImage = leadingSystemImage
        self.message = message
        self.emphasizedMessage = emphasizedMessage
        self.trailingTitle = trailingTitle
        self.trailingSystemImage = trailingSystemImage
        self.trailingTint = trailingTint
    }

    var body: some View {
        HStack(spacing: 10) {
            footerLabel(
                title: leadingTitle,
                systemImage: leadingSystemImage,
                tint: .secondary
            )

            Spacer(minLength: 12)

            if message != nil || emphasizedMessage != nil {
                HStack(spacing: 4) {
                    if let message {
                        Text(message)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }

                    if let emphasizedMessage {
                        Text(emphasizedMessage)
                            .lineLimit(1)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if let trailingTitle {
                Spacer(minLength: 12)

                footerLabel(
                    title: trailingTitle,
                    systemImage: trailingSystemImage,
                    tint: trailingTint
                )
            }
        }
        .font(.caption)
        .padding(.horizontal, DesignTokens.Spacing.panelInset)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func footerLabel(
        title: String,
        systemImage: String?,
        tint: Color
    ) -> some View {
        if let systemImage {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
                .foregroundStyle(tint)
        } else {
            Text(title)
                .lineLimit(1)
                .foregroundStyle(tint)
        }
    }
}

enum PanelSelectionTokens {
    static func background(isSelected: Bool, isHovered: Bool = false) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.16)
        }
        if isHovered {
            return Color(nsColor: .controlBackgroundColor).opacity(0.82)
        }
        return Color(nsColor: .controlBackgroundColor).opacity(0.45)
    }

    static func stroke(isSelected: Bool, isHovered: Bool = false) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.58)
        }
        if isHovered {
            return Color(nsColor: .separatorColor).opacity(0.46)
        }
        return Color(nsColor: .separatorColor).opacity(0.24)
    }

    static func primaryForeground(isSelected: Bool) -> Color {
        isSelected ? .primary : .primary
    }

    static func secondaryForeground(isSelected: Bool) -> Color {
        isSelected ? .primary.opacity(0.78) : .secondary
    }

    static func accessoryForeground(isSelected: Bool) -> Color {
        isSelected ? .accentColor : .secondary
    }

    static func badgeFill(_ color: Color, isSelected: Bool) -> Color {
        isSelected ? color.opacity(0.18) : color.opacity(0.12)
    }

    static func badgeStroke(_ color: Color, isSelected: Bool) -> Color {
        isSelected ? color.opacity(0.34) : color.opacity(0.24)
    }

    static func badgeForeground(_ color: Color, isSelected: Bool) -> Color {
        isSelected ? color : color
    }
}

private struct PanelSelectableRowBackground: ViewModifier {
    let isSelected: Bool
    let isHovered: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(PanelSelectionTokens.background(isSelected: isSelected, isHovered: isHovered), in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(PanelSelectionTokens.stroke(isSelected: isSelected, isHovered: isHovered), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}

extension View {
    func panelSelectableRowBackground(
        isSelected: Bool,
        isHovered: Bool = false,
        cornerRadius: CGFloat = DesignTokens.Radius.control
    ) -> some View {
        modifier(PanelSelectableRowBackground(isSelected: isSelected, isHovered: isHovered, cornerRadius: cornerRadius))
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

struct MenuBarItemIconView: View {
    let snapshot: MenuBarItemSnapshot
    let imageSize: CGSize
    let cornerRadius: CGFloat

    private let renderedIconCache: MenuBarRenderedIconCache
    private let appIconCache: AppIconCache
    private let appIconLookup: AppIconCache.Lookup

    @State private var iconImage: NSImage
    @State private var iconSource: MenuBarIconSource

    @MainActor
    init(
        snapshot: MenuBarItemSnapshot,
        size: CGFloat = 28,
        cornerRadius: CGFloat? = nil,
        renderedIconCache: MenuBarRenderedIconCache = .shared,
        appIconCache: AppIconCache = .shared
    ) {
        self.init(
            snapshot: snapshot,
            imageSize: CGSize(width: size, height: size),
            cornerRadius: cornerRadius,
            renderedIconCache: renderedIconCache,
            appIconCache: appIconCache
        )
    }

    @MainActor
    init(
        snapshot: MenuBarItemSnapshot,
        imageSize: CGSize,
        cornerRadius: CGFloat? = nil,
        renderedIconCache: MenuBarRenderedIconCache = .shared,
        appIconCache: AppIconCache = .shared
    ) {
        self.snapshot = snapshot
        self.imageSize = imageSize
        self.cornerRadius = cornerRadius ?? min(
            DesignTokens.Radius.icon,
            min(imageSize.width, imageSize.height) / 4
        )
        self.renderedIconCache = renderedIconCache
        self.appIconCache = appIconCache
        self.appIconLookup = AppIconCache.Lookup(snapshot: snapshot)

        if let rendered = renderedIconCache.resolvedImage(for: snapshot) {
            _iconImage = State(initialValue: rendered.image)
            _iconSource = State(initialValue: rendered.source)
        } else {
            _iconImage = State(initialValue: appIconCache.cachedIcon(for: appIconLookup) ?? appIconCache.placeholderIcon)
            _iconSource = State(initialValue: .bundleIconFallback)
        }
    }

    var body: some View {
        Image(nsImage: iconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageSize.width, height: imageSize.height)
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(iconSource == .renderedCapture ? 0.12 : 0.22), lineWidth: DesignTokens.Stroke.hairline)
            }
            .help(iconSource.displayName)
            .task(id: snapshot.id) { @MainActor in
                updateIcon(resolveFallback: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .menuBarRenderedIconCacheDidChange)) { notification in
                let identity = notification.userInfo?["identity"] as? String
                guard identity == nil || identity == snapshot.id else { return }
                updateIcon(resolveFallback: false)
            }
    }

    @MainActor
    private func updateIcon(resolveFallback: Bool) {
        if let rendered = renderedIconCache.resolvedImage(for: snapshot) {
            iconImage = rendered.image
            iconSource = rendered.source
            return
        }

        guard resolveFallback || iconSource != .bundleIconFallback else { return }
        iconImage = appIconCache.icon(for: appIconLookup, processIdentifier: snapshot.owningProcessIdentifier)
        iconSource = .bundleIconFallback
    }
}
