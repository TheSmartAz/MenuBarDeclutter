import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let xxLarge: CGFloat = 24
        static let panelInset: CGFloat = 18
    }

    enum Radius {
        static let control: CGFloat = 7
        static let group: CGFloat = 8
        static let panel: CGFloat = 12
        static let icon: CGFloat = 8
    }

    enum Stroke {
        static let hairline: CGFloat = 0.5
        static let standard: CGFloat = 1
    }

    enum IconSize {
        static let small: CGFloat = 14
        static let standard: CGFloat = 18
        static let large: CGFloat = 34
    }

    enum Typography {
        static let largeTitle: Font = .system(size: 28, weight: .semibold)
        static let title: Font = .system(size: 22, weight: .semibold)
        static let headline: Font = .system(size: 17, weight: .semibold)
        static let body: Font = .system(size: 14, weight: .regular)
        static let callout: Font = .system(size: 12, weight: .regular)
        static let subheadline: Font = .system(size: 11, weight: .regular)
        static let caption: Font = .system(size: 10, weight: .regular)
    }

    enum SemanticTone: String, CaseIterable, Sendable {
        case accent
        case privacySafe
        case permissionRequired
        case diagnostics
        case experimental
        case destructive
        case neutral
        case disabled

        var title: String {
            switch self {
            case .accent:
                "Active"
            case .privacySafe:
                "Privacy Safe"
            case .permissionRequired:
                "Permission Required"
            case .diagnostics:
                "Diagnostics"
            case .experimental:
                "Experimental"
            case .destructive:
                "Action Needed"
            case .neutral:
                "Neutral"
            case .disabled:
                "Disabled"
            }
        }

        var foregroundStyle: Color {
            switch self {
            case .accent:
                .accentColor
            case .privacySafe:
                .green
            case .permissionRequired:
                .orange
            case .diagnostics:
                .secondary
            case .experimental:
                .orange
            case .destructive:
                .red
            case .neutral:
                .primary
            case .disabled:
                .secondary
            }
        }

        var backgroundStyle: Color {
            switch self {
            case .neutral:
                Color(nsColor: .quaternaryLabelColor).opacity(0.10)
            case .disabled:
                .secondary.opacity(0.07)
            default:
                foregroundStyle.opacity(0.08)
            }
        }

        var borderStyle: Color {
            switch self {
            case .neutral, .disabled, .diagnostics:
                Color(nsColor: .separatorColor).opacity(0.48)
            default:
                foregroundStyle.opacity(0.20)
            }
        }
    }
}

struct ClearGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isProminent: Bool

    func body(content: Content) -> some View {
        content
            .background(
                isProminent ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color(nsColor: .controlBackgroundColor)),
                in: .rect(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}

extension View {
    func clearGlassSurface(
        cornerRadius: CGFloat = DesignTokens.Radius.group,
        isProminent: Bool = false
    ) -> some View {
        modifier(ClearGlassSurfaceModifier(cornerRadius: cornerRadius, isProminent: isProminent))
    }
}
