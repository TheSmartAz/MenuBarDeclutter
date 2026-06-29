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
                .blue
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
                .primary.opacity(0.06)
            case .disabled:
                .secondary.opacity(0.08)
            default:
                foregroundStyle.opacity(0.14)
            }
        }

        var borderStyle: Color {
            switch self {
            case .neutral, .disabled, .diagnostics:
                .secondary.opacity(0.22)
            default:
                foregroundStyle.opacity(0.32)
            }
        }
    }
}

struct ClearGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isProminent: Bool

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(isProminent ? 0.32 : 0.18), lineWidth: DesignTokens.Stroke.hairline)
            }
            .shadow(color: .black.opacity(isProminent ? 0.18 : 0.08), radius: isProminent ? 18 : 8, y: isProminent ? 8 : 3)
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
