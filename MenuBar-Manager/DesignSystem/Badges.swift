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
                "Pro Mode"
            case .privacySafe:
                "Privacy Safe"
            case .accessibilityRequired:
                "Accessibility Required"
            case .diagnostics:
                "Diagnostics"
            case .experimental:
                "Experimental"
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
            case .proMode, .neutral:
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
                Descriptor(shortTitle: "H", title: "Hidden", systemImage: "eye.slash", tone: .experimental)
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
