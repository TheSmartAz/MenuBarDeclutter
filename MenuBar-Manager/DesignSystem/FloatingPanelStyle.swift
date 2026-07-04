import AppKit
import SwiftUI

enum MenuBarDeclutterFloatingPanelStyle {
    static let cornerRadius: CGFloat = 14
    static let strokeOpacity: CGFloat = 0.58
    static let strokeWidth: CGFloat = 0.75
}

struct FloatingUnavailableStatePanel: View {
    struct Action {
        enum Style: String, Sendable {
            case primary
            case secondary

            var isProminent: Bool {
                self == .primary
            }
        }

        let title: String
        let style: Style
        let accessibilityIdentifier: String?
        let handler: () -> Void

        init(
            title: String,
            style: Style,
            accessibilityIdentifier: String? = nil,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.style = style
            self.accessibilityIdentifier = accessibilityIdentifier
            self.handler = handler
        }
    }

    let title: String
    let message: String
    let systemImage: String
    let privacyMessage: String
    let primaryAction: Action
    let secondaryAction: Action?
    let accessibilityIdentifier: String

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                iconBadge
                statusPill

                Text(title)
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Label("Next step: \(primaryAction.title)", systemImage: "arrow.right.circle")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        actionButtons
                    }

                    VStack(spacing: 8) {
                        actionButtons
                    }
                }
                .controlSize(.regular)
            }

            privacyCallout
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(maxWidth: 470, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.SemanticTone.disabled.backgroundStyle)
                .frame(width: 58, height: 58)

            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(DesignTokens.SemanticTone.disabled.foregroundStyle)
        }
    }

    private var statusPill: some View {
        Text("Unavailable")
            .font(.caption.bold())
            .foregroundStyle(DesignTokens.SemanticTone.disabled.foregroundStyle)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(DesignTokens.SemanticTone.disabled.backgroundStyle, in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(DesignTokens.SemanticTone.disabled.borderStyle, lineWidth: DesignTokens.Stroke.hairline)
            }
    }

    private var privacyCallout: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 16)

            Text(privacyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.07), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(Color.green.opacity(0.16), lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        actionButton(primaryAction)

        if let secondaryAction {
            actionButton(secondaryAction)
        }
    }

    @ViewBuilder
    private func actionButton(_ action: Action) -> some View {
        if action.style.isProminent {
            baseButton(action)
                .buttonStyle(.plain)
                .font(.body.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 17)
                .padding(.vertical, 7)
                .background(Color.accentColor, in: .rect(cornerRadius: 7))
        } else {
            baseButton(action)
                .buttonStyle(.plain)
                .font(.body.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 17)
                .padding(.vertical, 7)
                .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        }
    }

    @ViewBuilder
    private func baseButton(_ action: Action) -> some View {
        let button = Button(action.title, action: action.handler)
        if let accessibilityIdentifier = action.accessibilityIdentifier {
            button.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            button
        }
    }
}

@MainActor
extension NSPanel {
    func applyMenuBarDeclutterFloatingPanelStyle(title: String) {
        self.title = title
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .utilityWindow
    }
}

extension View {
    func menuBarDeclutterFloatingPanelChrome() -> some View {
        background(
            Color(nsColor: .windowBackgroundColor),
            in: RoundedRectangle(
                cornerRadius: MenuBarDeclutterFloatingPanelStyle.cornerRadius,
                style: .continuous
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: MenuBarDeclutterFloatingPanelStyle.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: MenuBarDeclutterFloatingPanelStyle.cornerRadius,
                style: .continuous
            )
            .stroke(
                Color(nsColor: .separatorColor).opacity(MenuBarDeclutterFloatingPanelStyle.strokeOpacity),
                lineWidth: MenuBarDeclutterFloatingPanelStyle.strokeWidth
            )
        }
    }
}
