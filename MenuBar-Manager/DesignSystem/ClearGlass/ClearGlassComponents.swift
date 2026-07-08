// Shared ClearGlass* design-system components, relocated out of
// SettingsRootView.swift (cleanup wave 2). Used across ~16 Settings views.
// Pure relocation within the module; no behavior change.

import AppKit
import Observation
import SwiftUI

enum ClearGlassSettingsPageStyle {
    case form
    case tool

    var maxContentWidth: CGFloat {
        rhythm.maxContentWidth
    }

    var contentSpacing: CGFloat {
        rhythm.contentSpacing
    }

    var horizontalPadding: CGFloat {
        rhythm.horizontalPadding
    }

    var topPadding: CGFloat {
        rhythm.topPadding
    }

    var bottomPadding: CGFloat {
        rhythm.bottomPadding
    }

    var headerInlineSpacing: CGFloat {
        rhythm.headerInlineSpacing
    }

    var headerStackSpacing: CGFloat {
        rhythm.headerStackSpacing
    }

    var sectionHeaderWidth: CGFloat {
        rhythm.sectionHeaderWidth
    }

    var sectionColumnSpacing: CGFloat {
        rhythm.sectionColumnSpacing
    }

    var sectionHeaderTopPadding: CGFloat {
        rhythm.sectionHeaderTopPadding
    }

    var sectionHeaderBodySpacing: CGFloat {
        rhythm.sectionHeaderBodySpacing
    }

    var nestedSectionSpacing: CGFloat {
        rhythm.nestedSectionSpacing
    }

    var sectionBodyHorizontalPadding: CGFloat {
        rhythm.sectionBodyHorizontalPadding
    }

    var sectionBodyVerticalPadding: CGFloat {
        rhythm.sectionBodyVerticalPadding
    }

    var nestedSectionBodyHorizontalPadding: CGFloat {
        rhythm.nestedSectionBodyHorizontalPadding
    }

    var nestedSectionBodyVerticalPadding: CGFloat {
        rhythm.nestedSectionBodyVerticalPadding
    }

    private var rhythm: ClearGlassSettingsPageRhythm {
        switch self {
        case .form:
            ClearGlassSettingsPageRhythm(
                maxContentWidth: 1040,
                horizontalPadding: 34,
                topPadding: 26,
                bottomPadding: 78,
                headerInlineSpacing: 18,
                headerStackSpacing: 13,
                contentSpacing: 28,
                sectionHeaderWidth: 190,
                sectionColumnSpacing: 24,
                sectionHeaderTopPadding: 10,
                sectionHeaderBodySpacing: 10,
                nestedSectionSpacing: 9,
                sectionBodyHorizontalPadding: 16,
                sectionBodyVerticalPadding: 9,
                nestedSectionBodyHorizontalPadding: 12,
                nestedSectionBodyVerticalPadding: 7
            )
        case .tool:
            ClearGlassSettingsPageRhythm(
                maxContentWidth: 1160,
                horizontalPadding: 34,
                topPadding: 24,
                bottomPadding: 82,
                headerInlineSpacing: 18,
                headerStackSpacing: 12,
                contentSpacing: 22,
                sectionHeaderWidth: 180,
                sectionColumnSpacing: 20,
                sectionHeaderTopPadding: 8,
                sectionHeaderBodySpacing: 11,
                nestedSectionSpacing: 9,
                sectionBodyHorizontalPadding: 16,
                sectionBodyVerticalPadding: 9,
                nestedSectionBodyHorizontalPadding: 12,
                nestedSectionBodyVerticalPadding: 7
            )
        }
    }
}

private struct ClearGlassSettingsPageRhythm {
    let maxContentWidth: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let headerInlineSpacing: CGFloat
    let headerStackSpacing: CGFloat
    let contentSpacing: CGFloat
    let sectionHeaderWidth: CGFloat
    let sectionColumnSpacing: CGFloat
    let sectionHeaderTopPadding: CGFloat
    let sectionHeaderBodySpacing: CGFloat
    let nestedSectionSpacing: CGFloat
    let sectionBodyHorizontalPadding: CGFloat
    let sectionBodyVerticalPadding: CGFloat
    let nestedSectionBodyHorizontalPadding: CGFloat
    let nestedSectionBodyVerticalPadding: CGFloat
}

private struct ClearGlassSettingsPageStyleKey: EnvironmentKey {
    static let defaultValue: ClearGlassSettingsPageStyle = .form
}

private extension EnvironmentValues {
    var clearGlassSettingsPageStyle: ClearGlassSettingsPageStyle {
        get { self[ClearGlassSettingsPageStyleKey.self] }
        set { self[ClearGlassSettingsPageStyleKey.self] = newValue }
    }
}

struct ClearGlassSettingsPage<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let badges: [ClearGlassBadgeStyle]
    private let style: ClearGlassSettingsPageStyle
    private let sectionAnchors: [ClearGlassPageAnchor]
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        badges: [ClearGlassBadgeStyle] = [],
        style: ClearGlassSettingsPageStyle = .form,
        sectionAnchors: [ClearGlassPageAnchor] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badges = badges
        self.style = style
        self.sectionAnchors = sectionAnchors
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: style.contentSpacing) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .bottom, spacing: style.headerInlineSpacing) {
                            ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)
                                .layoutPriority(1)

                            Spacer(minLength: style.headerInlineSpacing)

                            if sectionAnchors.count > 1 {
                                ClearGlassPageAnchorBar(anchors: sectionAnchors) { anchor in
                                    scroll(to: anchor, using: proxy)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: style.headerStackSpacing) {
                            ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)

                            if sectionAnchors.count > 1 {
                                ClearGlassPageAnchorBar(anchors: sectionAnchors) { anchor in
                                    scroll(to: anchor, using: proxy)
                                }
                            }
                        }
                    }
                    .id(ClearGlassPageAnchor.top.targetID)

                    content
                        .environment(\.clearGlassSettingsPageStyle, style)
                }
                .padding(.horizontal, style.horizontalPadding)
                .padding(.top, style.topPadding)
                .padding(.bottom, style.bottomPadding)
                .frame(maxWidth: style.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .accessibilityIdentifier("settings.page.scroll")
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func scroll(to anchor: ClearGlassPageAnchor, using proxy: ScrollViewProxy) {
        if accessibilityReduceMotion {
            proxy.scrollTo(anchor.targetID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(anchor.targetID, anchor: .top)
            }
        }
    }
}

struct ClearGlassPageAnchor: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let targetID: String

    var id: String { targetID }

    init(_ title: String, systemImage: String, targetID: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.targetID = targetID ?? title
    }

    static let top = ClearGlassPageAnchor("Top", systemImage: "arrow.up", targetID: "settings.page.top")
}

struct ClearGlassPageAnchorBar: View {
    let anchors: [ClearGlassPageAnchor]
    let onSelect: (ClearGlassPageAnchor) -> Void

    private var allAnchors: [ClearGlassPageAnchor] {
        [ClearGlassPageAnchor.top] + anchors
    }

    var body: some View {
        if anchors.count > 1 {
            compactAnchorMenu
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Page sections")
        }
    }

    private var compactAnchorMenu: some View {
        Menu {
            ForEach(allAnchors) { anchor in
                Button {
                    onSelect(anchor)
                } label: {
                    Label(anchor.title, systemImage: anchor.systemImage)
                }
            }
        } label: {
            Label("Sections", systemImage: "list.bullet")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Jump to page section")
        .accessibilityHint("Opens a menu of sections on this settings page.")
    }
}

private struct ClearGlassSectionDepthKey: EnvironmentKey {
    static let defaultValue = 0
}

private extension EnvironmentValues {
    var clearGlassSectionDepth: Int {
        get { self[ClearGlassSectionDepthKey.self] }
        set { self[ClearGlassSectionDepthKey.self] = newValue }
    }
}

struct ClearGlassSection<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let anchorID: String?
    @Environment(\.clearGlassSettingsPageStyle) private var pageStyle
    @Environment(\.clearGlassSectionDepth) private var sectionDepth
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        anchorID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.anchorID = anchorID
        self.content = content()
    }

    var body: some View {
        sectionLayout
            .environment(\.clearGlassSectionDepth, sectionDepth + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(anchorID ?? title)
    }

    @ViewBuilder
    private var sectionLayout: some View {
        if sectionDepth == 0 {
            switch pageStyle {
            case .form:
                formTopLevelSection
            case .tool:
                toolTopLevelSection
            }
        } else {
            nestedSection
        }
    }

    private var formTopLevelSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: pageStyle.sectionColumnSpacing) {
                sectionHeader
                    .frame(width: pageStyle.sectionHeaderWidth, alignment: .topLeading)
                    .padding(.top, pageStyle.sectionHeaderTopPadding)

                sectionBody()
                    .frame(minWidth: 360, maxWidth: .infinity, alignment: .topLeading)
            }

            verticalSection
        }
    }

    private var toolTopLevelSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.sectionHeaderBodySpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody()
        }
    }

    private var verticalSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.sectionHeaderBodySpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody()
        }
    }

    private var nestedSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.nestedSectionSpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody(isNested: true)
        }
        .padding(.vertical, 4)
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignTokens.Typography.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionBody(isNested: Bool = false) -> some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, isNested ? pageStyle.nestedSectionBodyHorizontalPadding : pageStyle.sectionBodyHorizontalPadding)
        .padding(.vertical, isNested ? pageStyle.nestedSectionBodyVerticalPadding : pageStyle.sectionBodyVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionFill(isNested: isNested), in: .rect(cornerRadius: DesignTokens.Radius.group))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                .strokeBorder(sectionBorder(isNested: isNested), lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private func sectionFill(isNested: Bool) -> Color {
        if isNested {
            return Color(nsColor: .quaternaryLabelColor).opacity(0.08)
        }

        return Color(nsColor: .controlBackgroundColor)
    }

    private func sectionBorder(isNested: Bool) -> Color {
        Color(nsColor: .separatorColor).opacity(isNested ? 0.38 : 0.58)
    }
}

struct ClearGlassToolSurface<Content: View>: View {
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat
    private let minHeight: CGFloat?
    @ViewBuilder private let content: Content

    init(
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0,
        minHeight: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: DesignTokens.Radius.group))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}

struct ClearGlassPaneLayout<Primary: View, Detail: View>: View {
    private let primaryWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let primary: Primary
    @ViewBuilder private let detail: Detail

    init(
        primaryWidth: CGFloat = 280,
        spacing: CGFloat = 14,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder detail: () -> Detail
    ) {
        self.primaryWidth = primaryWidth
        self.spacing = spacing
        self.primary = primary()
        self.detail = detail()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                primary
                    .frame(width: primaryWidth)

                detail
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: spacing) {
                primary
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                detail
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct ClearGlassButtonGrid<Content: View>: View {
    private let minimumItemWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let content: Content

    init(
        minimumItemWidth: CGFloat = 150,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = minimumItemWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth), spacing: spacing)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum ClearGlassInteractionSurface {
    case row
    case surface
    case tile
    case token

    var cornerRadius: CGFloat {
        switch self {
        case .row:
            7
        case .surface:
            8
        case .tile:
            8
        case .token:
            6
        }
    }

    var hoverFill: Color {
        switch self {
        case .row:
            Color.accentColor.opacity(0.045)
        case .surface:
            Color.accentColor.opacity(0.035)
        case .tile:
            Color.accentColor.opacity(0.045)
        case .token:
            Color.accentColor.opacity(0.05)
        }
    }

    var hoverStroke: Color {
        Color.accentColor.opacity(0.18)
    }

    var disabledFill: Color {
        Color(nsColor: .quaternaryLabelColor).opacity(0.08)
    }

    var disabledStroke: Color {
        Color(nsColor: .separatorColor).opacity(0.42)
    }
}

private struct ClearGlassInteractionFeedback: ViewModifier {
    let surface: ClearGlassInteractionSurface
    let isDimmed: Bool
    let helpText: String?

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    private var isInteractive: Bool {
        isEnabled && !isDimmed
    }

    func body(content: Content) -> some View {
        content
            .contentShape(.rect(cornerRadius: surface.cornerRadius))
            .background {
                RoundedRectangle(cornerRadius: surface.cornerRadius)
                    .fill(backgroundFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius)
                    .strokeBorder(strokeColor, style: strokeStyle)
            }
            .onHover { isHovered = $0 }
            .animation(accessibilityReduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
            .clearGlassHelp(helpText)
    }

    private var backgroundFill: Color {
        if !isInteractive {
            return surface.disabledFill
        }

        return isHovered ? surface.hoverFill : .clear
    }

    private var strokeColor: Color {
        if !isInteractive {
            return surface.disabledStroke
        }

        return isHovered ? surface.hoverStroke : .clear
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(
            lineWidth: isInteractive ? 0.75 : 0.5,
            dash: isInteractive ? [] : [3, 3]
        )
    }
}

extension View {
    func clearGlassInteractionFeedback(
        _ surface: ClearGlassInteractionSurface,
        isDimmed: Bool = false,
        help helpText: String? = nil
    ) -> some View {
        modifier(
            ClearGlassInteractionFeedback(
                surface: surface,
                isDimmed: isDimmed,
                helpText: helpText
            )
        )
    }

    @ViewBuilder
    func clearGlassHelp(_ helpText: String?) -> some View {
        if let helpText, !helpText.isEmpty {
            help(helpText)
        } else {
            self
        }
    }
}

struct ClearGlassOverviewMetric: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let systemImage: String
    let style: ClearGlassStatusStyle

    init(
        id: String? = nil,
        title: String,
        value: String,
        systemImage: String,
        style: ClearGlassStatusStyle = .secondary
    ) {
        self.id = id ?? title
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.style = style
    }
}

struct ClearGlassOverviewStrip: View {
    private let metrics: [ClearGlassOverviewMetric]
    private let minimumItemWidth: CGFloat
    private let maximumColumnCount: Int

    init(
        _ metrics: [ClearGlassOverviewMetric],
        minimumItemWidth: CGFloat = 120,
        maximumColumnCount: Int = 4
    ) {
        self.metrics = metrics
        self.minimumItemWidth = minimumItemWidth
        self.maximumColumnCount = max(1, maximumColumnCount)
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(metrics) { metric in
                ClearGlassOverviewMetricTile(metric: metric)
            }
        }
    }

    private var columns: [GridItem] {
        if maximumColumnCount < metrics.count {
            return Array(
                repeating: GridItem(.flexible(minimum: minimumItemWidth), spacing: 10),
                count: maximumColumnCount
            )
        }

        return [
            GridItem(.adaptive(minimum: minimumItemWidth), spacing: 10)
        ]
    }
}

private struct ClearGlassOverviewMetricTile: View {
    let metric: ClearGlassOverviewMetric

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: metric.systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(metric.style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(metric.value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
        .clearGlassInteractionFeedback(.tile, help: "\(metric.title): \(metric.value)")
    }
}

struct ClearGlassMetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
        }
        .clearGlassInteractionFeedback(.tile, help: "\(label): \(value)")
    }
}

struct ClearGlassGroupedList<Content: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let content: Content

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
        VStack(alignment: .leading, spacing: 7) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClearGlassStatusControlRow<Accessory: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String
    private let iconTint: Color
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    private let isDimmed: Bool
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String,
        iconTint: Color? = nil,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        isDimmed: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint ?? statusStyle.tint
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.isDimmed = isDimmed
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            title: title,
            subtitle: subtitle,
            statusText: statusText,
            statusStyle: statusStyle
        ) {
            accessory
        }
        .padding(.vertical, 8)
        .opacity(isDimmed ? 0.58 : 1)
        .clearGlassInteractionFeedback(.row, isDimmed: isDimmed, help: helpText)
        .accessibilityElement(children: .combine)
    }

    private var helpText: String {
        if let statusText {
            return "\(title). \(subtitle) Status: \(statusText)."
        }

        return "\(title). \(subtitle)"
    }
}

extension ClearGlassStatusControlRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String,
        iconTint: Color? = nil,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        isDimmed: Bool = false
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint,
            statusText: statusText,
            statusStyle: statusStyle,
            isDimmed: isDimmed
        ) {
            EmptyView()
        }
    }
}

enum ClearGlassAccessoryClusterAlignment {
    case leading
    case center
    case trailing
}

enum ClearGlassAccessoryClusterWidth {
    case compact
    case flexible
}

struct ClearGlassAccessoryCluster<Content: View>: View {
    private let alignment: ClearGlassAccessoryClusterAlignment
    private let spacing: CGFloat
    private let width: ClearGlassAccessoryClusterWidth
    private let appliesDefaultButtonStyle: Bool
    @ViewBuilder private let content: Content

    init(
        alignment: ClearGlassAccessoryClusterAlignment = .trailing,
        spacing: CGFloat = 8,
        width: ClearGlassAccessoryClusterWidth = .compact,
        appliesDefaultButtonStyle: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.width = width
        self.appliesDefaultButtonStyle = appliesDefaultButtonStyle
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content
            }
            .frame(maxWidth: horizontalMaxWidth, alignment: horizontalFrameAlignment)

            VStack(alignment: stackAlignment, spacing: spacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: verticalFrameAlignment)
        }
        .modifier(ClearGlassAccessoryButtonStyle(appliesDefaultStyle: appliesDefaultButtonStyle))
    }

    private var horizontalMaxWidth: CGFloat? {
        switch width {
        case .compact:
            return nil
        case .flexible:
            return .infinity
        }
    }

    private var horizontalFrameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        default:
            return .trailing
        }
    }

    private var stackAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private var verticalFrameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        default:
            return .trailing
        }
    }
}

private struct ClearGlassAccessoryButtonStyle: ViewModifier {
    let appliesDefaultStyle: Bool

    func body(content: Content) -> some View {
        if appliesDefaultStyle {
            content
                .buttonStyle(.bordered)
                .controlSize(.small)
        } else {
            content
        }
    }
}

enum ClearGlassRowIconStyle {
    case plain
    case tile

    var frameSize: CGFloat {
        switch self {
        case .plain:
            22
        case .tile:
            30
        }
    }

    var imageSize: CGFloat {
        switch self {
        case .plain:
            15
        case .tile:
            15
        }
    }

    var imageWeight: Font.Weight {
        switch self {
        case .plain:
            .regular
        case .tile:
            .medium
        }
    }
}

struct ClearGlassRowAnatomy<Accessory: View>: View {
    private let systemImage: String?
    private let iconTint: Color
    private let iconStyle: ClearGlassRowIconStyle
    private let title: String
    private let subtitle: String?
    private let titleFont: Font
    private let subtitleFont: Font
    private let subtitleLineLimit: Int
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    private let accessoryAlignment: ClearGlassAccessoryClusterAlignment
    private let accessoryWidth: ClearGlassAccessoryClusterWidth
    private let accessorySpacing: CGFloat
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        iconStyle: ClearGlassRowIconStyle = .plain,
        title: String,
        subtitle: String? = nil,
        titleFont: Font = .body,
        subtitleFont: Font = .callout,
        subtitleLineLimit: Int = 3,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        accessoryAlignment: ClearGlassAccessoryClusterAlignment = .trailing,
        accessoryWidth: ClearGlassAccessoryClusterWidth = .compact,
        accessorySpacing: CGFloat = 10,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.subtitleLineLimit = subtitleLineLimit
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.accessoryAlignment = accessoryAlignment
        self.accessoryWidth = accessoryWidth
        self.accessorySpacing = accessorySpacing
        self.accessory = accessory()
    }

    var body: some View {
        horizontalLayout
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView

            labelContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Spacer(minLength: 16)

            trailingContent
                .fixedSize(horizontal: usesCompactAccessoryWidth, vertical: false)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let systemImage {
            switch iconStyle {
            case .plain:
                Image(systemName: systemImage)
                    .font(.system(size: iconStyle.imageSize, weight: iconStyle.imageWeight))
                    .foregroundStyle(iconTint)
                    .frame(width: iconStyle.frameSize, height: iconStyle.frameSize)
            case .tile:
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconTint.opacity(0.12))

                    Image(systemName: systemImage)
                        .font(.system(size: iconStyle.imageSize, weight: iconStyle.imageWeight))
                        .foregroundStyle(iconTint)
                }
                .frame(width: iconStyle.frameSize, height: iconStyle.frameSize)
            }
        }
    }

    private var labelContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(subtitleLineLimit)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var trailingContent: some View {
        ClearGlassAccessoryCluster(
            alignment: accessoryAlignment,
            spacing: accessorySpacing,
            width: accessoryWidth
        ) {
            if let statusText {
                ClearGlassStatusValue(text: statusText, style: statusStyle)
            }

            accessory
        }
    }

    private var usesCompactAccessoryWidth: Bool {
        switch accessoryWidth {
        case .compact:
            true
        case .flexible:
            false
        }
    }
}

extension ClearGlassRowAnatomy where Accessory == EmptyView {
    init(
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        iconStyle: ClearGlassRowIconStyle = .plain,
        title: String,
        subtitle: String? = nil,
        titleFont: Font = .body,
        subtitleFont: Font = .callout,
        subtitleLineLimit: Int = 3,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: iconStyle,
            title: title,
            subtitle: subtitle,
            titleFont: titleFont,
            subtitleFont: subtitleFont,
            subtitleLineLimit: subtitleLineLimit,
            statusText: statusText,
            statusStyle: statusStyle
        ) {
            EmptyView()
        }
    }
}

struct ClearGlassActionStrip<Actions: View>: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String
    private let iconTint: Color
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    @ViewBuilder private let actions: Actions

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String = "bolt",
        iconTint: Color = .accentColor,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.actions = actions()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 1)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
        .clearGlassInteractionFeedback(.surface, help: helpText)
    }

    private var helpText: String {
        let detail = subtitle.map { "\(title). \($0)" } ?? title
        if let statusText {
            return "\(detail) Status: \(statusText)."
        }

        return detail
    }

    private var horizontalLayout: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: .tile,
            title: title,
            subtitle: subtitle,
            titleFont: .body.weight(.semibold),
            statusText: statusText,
            statusStyle: statusStyle,
            accessoryAlignment: .leading,
            accessoryWidth: .flexible
        ) {
            actionRow
        }
    }

    private var verticalLayout: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: .tile,
            title: title,
            subtitle: subtitle,
            titleFont: .body.weight(.semibold),
            statusText: statusText,
            statusStyle: statusStyle,
            accessoryAlignment: .leading,
            accessoryWidth: .flexible
        ) {
            actionRow
        }
    }

    private var actionRow: some View {
        ClearGlassAccessoryCluster(
            alignment: .leading,
            width: .flexible,
            appliesDefaultButtonStyle: true
        ) {
            actions
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.26), lineWidth: 0.5)
        }
    }
}

struct ClearGlassControlRow<Accessory: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let iconTint: Color
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            title: title,
            subtitle: subtitle
        ) {
            accessory
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        subtitle.map { "\(title). \($0)" } ?? title
    }
}

extension ClearGlassControlRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint
        ) {
            EmptyView()
        }
    }
}

struct ClearGlassValueRow<ValueContent: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let value: ValueContent

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder value: () -> ValueContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            title: title,
            subtitle: subtitle
        ) {
            value
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        subtitle.map { "\(title). \($0)" } ?? title
    }
}

struct ClearGlassSliderRow: View {
    private let title: String
    private let subtitle: String?
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let valueSuffix: String
    private let valueFractionLength: Int
    private let valueWidth: CGFloat

    init(
        _ title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        valueSuffix: String = "",
        valueFractionLength: Int = 0,
        valueWidth: CGFloat = 58
    ) {
        self.title = title
        self.subtitle = subtitle
        _value = value
        self.range = range
        self.step = step
        self.valueSuffix = valueSuffix
        self.valueFractionLength = valueFractionLength
        self.valueWidth = valueWidth
    }

    var body: some View {
        ClearGlassRowAnatomy(
            title: title,
            subtitle: subtitle,
            accessoryAlignment: .leading
        ) {
            HStack(spacing: 12) {
                Slider(value: $value, in: range, step: step)
                    .frame(minWidth: 220, idealWidth: 300, maxWidth: 320)

                valueText
            }
        }
        .padding(.vertical, 7)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        if let subtitle {
            return "\(title). \(subtitle) Current value: \(formattedValue)."
        }

        return "\(title). Current value: \(formattedValue)."
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(valueFractionLength))) + valueSuffix
    }
    private var valueText: some View {
        Text(formattedValue)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: valueWidth, alignment: .trailing)
    }
}

struct ClearGlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.55))
            .frame(height: 0.5)
            .padding(.leading, 34)
    }
}

struct ClearGlassInlineMessage: View {
    let text: String
    var systemImage: String = "info.circle"
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(style.tint)
                .frame(width: 18)

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.background, in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(style.border, lineWidth: 0.5)
        }
        .help(text)
    }
}

struct ClearGlassStatusValue: View {
    let text: String
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(style.tint)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.callout)
                .foregroundStyle(style.foreground)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .help("Status: \(text)")
    }
}

struct KeyboardShortcutToken: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
            }
            .clearGlassInteractionFeedback(.token, help: "Keyboard shortcut: \(text)")
            .accessibilityLabel("Keyboard shortcut \(text)")
    }
}

struct CommandAvailabilityRow: View {
    let summary: MenuBarCommandAvailabilitySummary

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: summary.systemImage,
            iconTint: summary.tone.clearGlassTint,
            iconStyle: .tile,
            title: summary.title,
            subtitle: summary.detail,
            statusText: summary.statusText,
            statusStyle: summary.tone.clearGlassStyle
        )
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: "\(summary.title). \(summary.detail) Status: \(summary.statusText).")
    }
}

private extension MenuBarCommandAvailabilityTone {
    var clearGlassStyle: ClearGlassStatusStyle {
        switch self {
        case .success:
            .success
        case .warning:
            .warning
        case .danger:
            .danger
        case .info:
            .info
        case .secondary:
            .secondary
        }
    }

    var clearGlassTint: Color {
        clearGlassStyle.tint
    }
}

enum ClearGlassStatusStyle {
    case success
    case warning
    case danger
    case info
    case secondary

    var tint: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var foreground: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var background: Color {
        switch self {
        case .success:
            Color.green.opacity(0.08)
        case .warning:
            Color.orange.opacity(0.10)
        case .danger:
            Color.red.opacity(0.08)
        case .info:
            Color.accentColor.opacity(0.08)
        case .secondary:
            Color(nsColor: .quaternaryLabelColor).opacity(0.10)
        }
    }

    var border: Color {
        switch self {
        case .success:
            Color.green.opacity(0.22)
        case .warning:
            Color.orange.opacity(0.26)
        case .danger:
            Color.red.opacity(0.22)
        case .info:
            Color.accentColor.opacity(0.20)
        case .secondary:
            Color(nsColor: .separatorColor).opacity(0.45)
        }
    }
}

struct ClearGlassBadge: View {
    let style: ClearGlassBadgeStyle

    var body: some View {
        Label(style.title, systemImage: style.systemImage)
            .font(.caption)
            .foregroundStyle(style.tint)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(style.tint.opacity(0.08), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(style.tint.opacity(0.18), lineWidth: 0.5)
            }
            .help(style.helpText)
    }
}

enum ClearGlassBadgeStyle: Hashable {
    case basicMode
    case privacySafe
    case proMode
    case accessibilityRequired
    case optionalProOff
    case discoveryOff
    case permissionNeeded
    case ready
    case diagnostics
    case stable
    case preview
    case labs
    case experimental
    case unavailable
    case deferred
    case actionNeeded

    init(featureStatus: FeatureStatus) {
        switch featureStatus {
        case .stable:
            self = .stable
        case .preview:
            self = .preview
        case .labs:
            self = .labs
        case .experimental:
            self = .experimental
        case .disabled, .unavailable:
            self = .unavailable
        case .deferred:
            self = .deferred
        }
    }

    var title: String {
        switch self {
        case .basicMode:
            "Basic Mode"
        case .privacySafe:
            "Privacy Safe"
        case .proMode:
            "Optional Pro"
        case .accessibilityRequired:
            "Accessibility"
        case .optionalProOff:
            "Optional Pro Off"
        case .discoveryOff:
            "Discovery Off"
        case .permissionNeeded:
            "Needs Permission"
        case .ready:
            "Ready"
        case .diagnostics:
            "Diagnostics"
        case .stable:
            FeatureStatus.stable.title
        case .preview:
            FeatureStatus.preview.title
        case .labs:
            FeatureStatus.labs.title
        case .experimental:
            FeatureStatus.labs.title
        case .unavailable:
            FeatureStatus.unavailable.title
        case .deferred:
            FeatureStatus.deferred.title
        case .actionNeeded:
            "Action Needed"
        }
    }

    var systemImage: String {
        switch self {
        case .basicMode:
            "checkmark.shield"
        case .privacySafe:
            "shield.lefthalf.filled"
        case .proMode:
            "star"
        case .accessibilityRequired:
            "figure.circle"
        case .optionalProOff:
            "star.slash"
        case .discoveryOff:
            "eye.slash"
        case .permissionNeeded:
            "hand.raised"
        case .ready:
            "checkmark.circle"
        case .diagnostics:
            "waveform.path.ecg"
        case .stable:
            FeatureStatus.stable.systemImage
        case .preview:
            FeatureStatus.preview.systemImage
        case .labs:
            FeatureStatus.labs.systemImage
        case .experimental:
            FeatureStatus.labs.systemImage
        case .unavailable:
            FeatureStatus.unavailable.systemImage
        case .deferred:
            FeatureStatus.deferred.systemImage
        case .actionNeeded:
            "exclamationmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .basicMode, .privacySafe:
            .green
        case .proMode:
            .accentColor
        case .accessibilityRequired:
            DesignTokens.SemanticTone.permissionRequired.foregroundStyle
        case .optionalProOff:
            .secondary
        case .discoveryOff:
            .orange
        case .permissionNeeded:
            DesignTokens.SemanticTone.permissionRequired.foregroundStyle
        case .ready:
            .green
        case .diagnostics:
            .secondary
        case .stable:
            FeatureStatus.stable.tint
        case .preview:
            FeatureStatus.preview.tint
        case .labs:
            FeatureStatus.labs.tint
        case .experimental:
            FeatureStatus.labs.tint
        case .unavailable:
            FeatureStatus.unavailable.tint
        case .deferred:
            FeatureStatus.deferred.tint
        case .actionNeeded:
            .red
        }
    }

    var helpText: String {
        switch self {
        case .basicMode:
            "Basic Mode: available without elevated permissions."
        case .privacySafe:
            "Privacy Safe: local-first behavior without network access."
        case .proMode:
            "Optional Pro capability."
        case .accessibilityRequired:
            "Requires Accessibility permission before use."
        case .optionalProOff:
            "Optional Pro is off."
        case .discoveryOff:
            "Discovery is off."
        case .permissionNeeded:
            "Permission is needed before this capability can run."
        case .ready:
            "Ready to use."
        case .diagnostics:
            "Diagnostics information."
        case .stable:
            FeatureStatus.stable.summary
        case .preview:
            FeatureStatus.preview.summary
        case .labs:
            FeatureStatus.labs.summary
        case .experimental:
            FeatureStatus.labs.summary
        case .unavailable:
            FeatureStatus.unavailable.summary
        case .deferred:
            FeatureStatus.deferred.summary
        case .actionNeeded:
            "Action is needed before this item is ready."
        }
    }
}

private struct ClearGlassPageHeader: View {
    let title: String
    let subtitle: String?
    let badges: [ClearGlassBadgeStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titleText
                    badgeStrip
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    titleText
                    badgeStrip
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleText: some View {
        Text(title)
            .font(.largeTitle)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var badgeStrip: some View {
        if !visibleBadges.isEmpty {
            HStack(spacing: 7) {
                ForEach(visibleBadges, id: \.self) { badge in
                    ClearGlassBadge(style: badge)
                }
            }
        }
    }

    private var visibleBadges: [ClearGlassBadgeStyle] {
        let actionable = badges
            .filter { !$0.isQuietHeaderBadge }
            .sorted { $0.headerPriority < $1.headerPriority }

        if !actionable.isEmpty {
            return Array(actionable.prefix(1))
        }

        for preferred in [ClearGlassBadgeStyle.basicMode, .privacySafe, .stable] where badges.contains(preferred) {
            return [preferred]
        }

        return Array(badges.prefix(1))
    }
}

private extension ClearGlassBadgeStyle {
    var isQuietHeaderBadge: Bool {
        switch self {
        case .basicMode, .privacySafe, .stable:
            true
        case .proMode,
             .accessibilityRequired,
             .optionalProOff,
             .discoveryOff,
             .permissionNeeded,
             .ready,
             .diagnostics,
             .preview,
             .labs,
             .experimental,
             .unavailable,
             .deferred,
             .actionNeeded:
            false
        }
    }

    var headerPriority: Int {
        switch self {
        case .actionNeeded:
            0
        case .permissionNeeded:
            1
        case .discoveryOff:
            2
        case .optionalProOff:
            3
        case .accessibilityRequired:
            4
        case .proMode:
            5
        case .labs:
            6
        case .experimental:
            7
        case .preview:
            8
        case .ready:
            9
        case .unavailable:
            10
        case .deferred:
            11
        case .diagnostics:
            12
        case .basicMode, .privacySafe, .stable:
            20
        }
    }
}

extension ClearGlassBadgeStyle {
    static func optionalProDiscovery(
        proModeEnabled: Bool,
        accessibilityDiscoveryEnabled: Bool,
        accessibilityPermissionStatus: AccessibilityPermissionStatus?
    ) -> ClearGlassBadgeStyle {
        guard proModeEnabled else {
            return .optionalProOff
        }

        guard accessibilityDiscoveryEnabled else {
            return .discoveryOff
        }

        guard accessibilityPermissionStatus == .granted else {
            return .permissionNeeded
        }

        return .ready
    }
}
