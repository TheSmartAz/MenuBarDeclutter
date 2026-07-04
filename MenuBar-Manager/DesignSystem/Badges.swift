import SwiftUI

struct StatusBadge: View {
    enum Style: String, CaseIterable, Sendable {
        case basicMode
        case proMode
        case privacySafe
        case accessibilityRequired
        case diagnostics
        case experimental
        case actionNeeded
        case neutral

        var defaultTitle: String {
            switch self {
            case .basicMode:
                "Basic Mode"
            case .proMode:
                "Optional Pro"
            case .privacySafe:
                "Privacy Safe"
            case .accessibilityRequired:
                "Unavailable"
            case .diagnostics:
                "Diagnostics"
            case .experimental:
                "Labs"
            case .actionNeeded:
                "Action Needed"
            case .neutral:
                "Status"
            }
        }

        var defaultSubtitle: String? {
            switch self {
            case .basicMode:
                "Privacy Safe"
            case .proMode:
                "Opt-in"
            case .accessibilityRequired:
                "Permission needed"
            default:
                nil
            }
        }

        var systemImage: String {
            switch self {
            case .basicMode, .privacySafe:
                "checkmark.shield"
            case .proMode:
                "star"
            case .accessibilityRequired:
                "accessibility"
            case .diagnostics:
                "waveform.path.ecg"
            case .experimental:
                "flask"
            case .actionNeeded:
                "exclamationmark.circle"
            case .neutral:
                "info.circle"
            }
        }

        var tone: DesignTokens.SemanticTone {
            switch self {
            case .basicMode, .privacySafe:
                .privacySafe
            case .proMode:
                .accent
            case .neutral:
                .neutral
            case .accessibilityRequired:
                .permissionRequired
            case .diagnostics:
                .diagnostics
            case .experimental:
                .experimental
            case .actionNeeded:
                .destructive
            }
        }

        var isProminent: Bool {
            switch self {
            case .basicMode:
                true
            default:
                false
            }
        }

        var accessibilityDescription: String {
            if let defaultSubtitle {
                "\(defaultTitle), \(defaultSubtitle)"
            } else {
                defaultTitle
            }
        }
    }

    enum Size: String, Sendable {
        case compact
        case regular
        case mode

        var iconSize: CGFloat {
            switch self {
            case .compact:
                13
            case .regular:
                14
            case .mode:
                24
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact:
                8
            case .regular:
                10
            case .mode:
                18
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact:
                4
            case .regular:
                6
            case .mode:
                12
            }
        }
    }

    let title: String
    let subtitle: String?
    let style: Style
    let size: Size

    init(
        _ style: Style,
        title: String? = nil,
        subtitle: String? = nil,
        size: Size = .regular
    ) {
        self.style = style
        self.title = title ?? style.defaultTitle
        self.subtitle = subtitle ?? style.defaultSubtitle
        self.size = size
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: style.systemImage)
                .font(.system(size: size.iconSize, weight: .semibold))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(size == .mode ? DesignTokens.Typography.body.bold() : DesignTokens.Typography.callout)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.subheadline)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .foregroundStyle(style.tone.foregroundStyle)
        .background(style.tone.backgroundStyle, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(style.tone.borderStyle, lineWidth: DesignTokens.Stroke.standard)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.accessibilityDescription)
    }
}

enum FeatureStatus: String, CaseIterable, Hashable, Sendable {
    case stable
    case preview
    case labs
    case experimental
    case disabled
    case unavailable
    case deferred

    var title: String {
        switch self {
        case .stable:
            "Stable"
        case .preview:
            "Preview"
        case .labs:
            "Labs"
        case .experimental:
            "Labs"
        case .disabled:
            "Disabled"
        case .unavailable:
            "Unavailable"
        case .deferred:
            "Deferred"
        }
    }

    var summary: String {
        switch self {
        case .stable:
            "Part of the v0.1.3 supported core."
        case .preview:
            "Available for local testing, with conservative gates and fail-closed behavior."
        case .labs:
            "Requires explicit opt-in and may affect system-level behavior."
        case .experimental:
            "Requires explicit confirmation and may fail depending on macOS state."
        case .disabled:
            "Currently turned off by app settings."
        case .unavailable:
            "Unavailable until requirements are satisfied."
        case .deferred:
            "Documented for later work and not part of this release."
        }
    }

    var systemImage: String {
        switch self {
        case .stable:
            "checkmark.seal"
        case .preview:
            "sparkles"
        case .labs:
            "testtube.2"
        case .experimental:
            "exclamationmark.triangle"
        case .disabled:
            "slash.circle"
        case .unavailable:
            "lock.circle"
        case .deferred:
            "clock"
        }
    }

    var tone: DesignTokens.SemanticTone {
        switch self {
        case .stable:
            .privacySafe
        case .preview:
            .accent
        case .labs, .experimental:
            .experimental
        case .disabled, .unavailable, .deferred:
            .disabled
        }
    }

    var tint: Color {
        tone.foregroundStyle
    }

    var isReleaseCore: Bool {
        self == .stable
    }

    var requiresExplicitOptIn: Bool {
        switch self {
        case .labs, .experimental:
            true
        default:
            false
        }
    }
}

struct FeatureStatusBadge: View {
    let status: FeatureStatus

    init(_ status: FeatureStatus) {
        self.status = status
    }

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(DesignTokens.Typography.callout.weight(.medium))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(status.tone.foregroundStyle)
            .background(status.tone.backgroundStyle, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(status.tone.borderStyle, lineWidth: DesignTokens.Stroke.standard)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(status.title). \(status.summary)")
    }
}

struct FeatureGateNotice: View {
    let status: FeatureStatus
    let text: String

    init(_ status: FeatureStatus, text: String? = nil) {
        self.status = status
        self.text = text ?? status.summary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            FeatureStatusBadge(status)

            Text(text)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct MenuBarZoneBadge: View {
    struct Descriptor: Equatable, Sendable {
        let shortTitle: String
        let title: String
        let systemImage: String
        let tone: DesignTokens.SemanticTone

        static func descriptor(for zone: MenuBarZone) -> Descriptor {
            switch zone {
            case .visible:
                Descriptor(shortTitle: "V", title: "Visible", systemImage: "eye", tone: .privacySafe)
            case .hidden:
                Descriptor(shortTitle: "H", title: "Hidden", systemImage: "eye.slash", tone: .accent)
            case .alwaysHidden:
                Descriptor(shortTitle: "A", title: "Always Hidden", systemImage: "lock", tone: .destructive)
            case .unknown:
                Descriptor(shortTitle: "?", title: "Unknown", systemImage: "questionmark.circle", tone: .disabled)
            }
        }
    }

    enum Size: String, Sendable {
        case compact
        case regular

        var font: Font {
            switch self {
            case .compact:
                .caption2
            case .regular:
                .caption
            }
        }
    }

    let descriptor: Descriptor
    let size: Size
    let showsIcon: Bool

    init(
        zone: MenuBarZone,
        size: Size = .compact,
        showsIcon: Bool = false
    ) {
        self.descriptor = Descriptor.descriptor(for: zone)
        self.size = size
        self.showsIcon = showsIcon
    }

    init(
        descriptor: Descriptor,
        size: Size = .compact,
        showsIcon: Bool = false
    ) {
        self.descriptor = descriptor
        self.size = size
        self.showsIcon = showsIcon
    }

    var body: some View {
        HStack(spacing: 4) {
            if showsIcon {
                Image(systemName: descriptor.systemImage)
            }

            Text(descriptor.shortTitle)
        }
        .font(size.font.bold())
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .foregroundStyle(descriptor.tone.foregroundStyle)
        .background(descriptor.tone.backgroundStyle, in: .capsule)
        .overlay {
            Capsule()
                .strokeBorder(descriptor.tone.borderStyle, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(descriptor.title)
    }
}
