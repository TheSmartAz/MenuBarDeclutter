import SwiftUI

struct RequirementRow: View {
    enum Status: String, CaseIterable, Sendable {
        case satisfied
        case optional
        case required
        case unavailable

        static func permissionBoundary(
            isSatisfied: Bool,
            isRequired: Bool,
            isAvailable: Bool = true
        ) -> Status {
            guard isAvailable else { return .unavailable }
            if isSatisfied { return .satisfied }
            return isRequired ? .required : .optional
        }

        var title: String {
            switch self {
            case .satisfied:
                "Enabled"
            case .optional:
                "Optional"
            case .required:
                "Required"
            case .unavailable:
                "Unavailable"
            }
        }

        var systemImage: String {
            switch self {
            case .satisfied:
                "checkmark.circle.fill"
            case .optional:
                "circle"
            case .required:
                "exclamationmark.circle"
            case .unavailable:
                "xmark.circle"
            }
        }

        var tone: DesignTokens.SemanticTone {
            switch self {
            case .satisfied:
                .privacySafe
            case .optional:
                .neutral
            case .required:
                .permissionRequired
            case .unavailable:
                .disabled
            }
        }

        var isBlocking: Bool {
            switch self {
            case .required, .unavailable:
                true
            case .satisfied, .optional:
                false
            }
        }
    }

    let title: String
    let detail: String?
    let status: Status
    let statusText: String?

    init(
        title: String,
        detail: String? = nil,
        status: Status,
        statusText: String? = nil
    ) {
        self.title = title
        self.detail = detail
        self.status = status
        self.statusText = statusText
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.large) {
            Image(systemName: status.systemImage)
                .frame(width: DesignTokens.IconSize.standard)
                .foregroundStyle(status.tone.foregroundStyle)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.body)

                if let detail {
                    Text(detail)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.large)

            Text(statusText ?? status.title)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct NoticeBanner: View {
    enum Kind: String, CaseIterable, Sendable {
        case info
        case privacy
        case success
        case warning
        case destructive

        var systemImage: String {
            switch self {
            case .info:
                "info.circle"
            case .privacy:
                "hand.raised"
            case .success:
                "checkmark.circle"
            case .warning:
                "exclamationmark.triangle"
            case .destructive:
                "exclamationmark.octagon"
            }
        }

        var tone: DesignTokens.SemanticTone {
            switch self {
            case .info:
                .accent
            case .privacy, .success:
                .privacySafe
            case .warning:
                .permissionRequired
            case .destructive:
                .destructive
            }
        }

        var accessibilityPrefix: String {
            switch self {
            case .info:
                "Information"
            case .privacy:
                "Privacy"
            case .success:
                "Success"
            case .warning:
                "Warning"
            case .destructive:
                "Action needed"
            }
        }
    }

    struct Action {
        let title: String
        let systemImage: String?
        let handler: () -> Void

        init(
            title: String,
            systemImage: String? = nil,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.handler = handler
        }
    }

    let title: String
    let message: String
    let kind: Kind
    let action: Action?

    init(
        title: String,
        message: String,
        kind: Kind = .info,
        action: Action? = nil
    ) {
        self.title = title
        self.message = message
        self.kind = kind
        self.action = action
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.large) {
            Image(systemName: kind.systemImage)
                .font(.system(size: DesignTokens.IconSize.standard, weight: .semibold))
                .foregroundStyle(kind.tone.foregroundStyle)
                .frame(width: DesignTokens.IconSize.standard)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(title)
                    .font(DesignTokens.Typography.body.bold())

                Text(message)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: DesignTokens.Spacing.large)

            if let action {
                Button(action.title, systemImage: action.systemImage ?? "arrow.right", action: action.handler)
                    .buttonStyle(.borderless)
            }
        }
        .padding(DesignTokens.Spacing.large)
        .background(kind.tone.backgroundStyle, in: .rect(cornerRadius: DesignTokens.Radius.group))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                .strokeBorder(kind.tone.borderStyle, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.accessibilityPrefix): \(title)")
    }
}

struct PrivacyTrustBoundarySummary: View {
    private let maximumWidth: CGFloat?
    private let accessibilityIdentifier: String

    private let basicItems = [
        PrivacyTrustBoundaryItem(title: "No sensitive permissions", systemImage: "checkmark.circle"),
        PrivacyTrustBoundaryItem(title: "No network access", systemImage: "network.slash"),
        PrivacyTrustBoundaryItem(title: "Local controls stay usable", systemImage: "lock.open")
    ]

    private let optionalProItems = [
        PrivacyTrustBoundaryItem(title: "Off until enabled", systemImage: "power"),
        PrivacyTrustBoundaryItem(title: "Permission prompt only from your button press", systemImage: "hand.raised"),
        PrivacyTrustBoundaryItem(title: "Basic Mode keeps working if denied", systemImage: "checkmark.circle")
    ]

    init(
        maximumWidth: CGFloat? = nil,
        accessibilityIdentifier: String = "privacy.trustBoundary"
    ) {
        self.maximumWidth = maximumWidth
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.large) {
                basicModeCard
                optionalProCard
            }

            VStack(spacing: DesignTokens.Spacing.large) {
                basicModeCard
                optionalProCard
            }
        }
        .frame(maxWidth: maximumWidth ?? .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var basicModeCard: some View {
        PrivacyTrustBoundaryCard(
            title: "Basic Mode",
            systemImage: "checkmark.shield",
            tint: .green,
            items: basicItems
        )
    }

    private var optionalProCard: some View {
        PrivacyTrustBoundaryCard(
            title: "Optional Pro",
            systemImage: "lock",
            tint: .accentColor,
            items: optionalProItems
        )
    }
}

private struct PrivacyTrustBoundaryItem: Hashable {
    let title: String
    let systemImage: String
}

private struct PrivacyTrustBoundaryCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let items: [PrivacyTrustBoundaryItem]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Label(title, systemImage: systemImage)
                .font(DesignTokens.Typography.body.bold())
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                ForEach(items, id: \.self) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignTokens.Spacing.large)
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .clearGlassSurface()
    }
}

struct UnavailablePanel: View {
    struct Action {
        enum Style: String, Sendable {
            case primary
            case secondary
            case destructive

            var role: ButtonRole? {
                switch self {
                case .primary, .secondary:
                    nil
                case .destructive:
                    .destructive
                }
            }

            var isProminent: Bool {
                self == .primary
            }
        }

        let title: String
        let systemImage: String?
        let style: Style
        let handler: () -> Void

        init(
            title: String,
            systemImage: String? = nil,
            style: Style = .primary,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.systemImage = systemImage
            self.style = style
            self.handler = handler
        }
    }

    let title: String
    let message: String
    let systemImage: String
    let primaryAction: Action?
    let secondaryAction: Action?

    init(
        title: String,
        message: String,
        systemImage: String,
        primaryAction: Action? = nil,
        secondaryAction: Action? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: DesignTokens.IconSize.large, weight: .regular))
                .foregroundStyle(.secondary)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(title)
                    .font(DesignTokens.Typography.headline)

                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 420)
            }

            if primaryAction != nil || secondaryAction != nil {
                HStack(spacing: DesignTokens.Spacing.medium) {
                    if let primaryAction {
                        panelButton(primaryAction)
                    }

                    if let secondaryAction {
                        panelButton(secondaryAction)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func panelButton(_ action: Action) -> some View {
        if action.style.isProminent {
            Button(role: action.style.role, action: action.handler) {
                if let systemImage = action.systemImage {
                    Label(action.title, systemImage: systemImage)
                } else {
                    Text(action.title)
                }
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button(role: action.style.role, action: action.handler) {
                if let systemImage = action.systemImage {
                    Label(action.title, systemImage: systemImage)
                } else {
                    Text(action.title)
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
