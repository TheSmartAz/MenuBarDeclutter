import SwiftUI

enum SettingsUnavailableReason: Sendable {
    case proModeDisabled
    case permissionMissing(status: String? = nil)
    case previewDisabled
    case emptyData
    case safeModeActive
    case serviceUnavailable
    case noMatches

    var defaultTitle: String {
        switch self {
        case .proModeDisabled:
            "Optional Pro Off"
        case .permissionMissing:
            "Unavailable"
        case .previewDisabled:
            "Preview Disabled"
        case .emptyData:
            "Nothing Here Yet"
        case .safeModeActive:
            "Safe Mode Active"
        case .serviceUnavailable:
            "Unavailable"
        case .noMatches:
            "No Matches"
        }
    }

    var defaultMessage: String {
        switch self {
        case .proModeDisabled:
            "This is available only after Optional Pro is enabled. Basic Mode remains usable without extra permissions."
        case .permissionMissing(let status):
            if let status {
                "Accessibility permission is \(status.lowercased()). Grant permission from Privacy settings to use this feature."
            } else {
                "A required permission is missing. Basic Mode remains usable while this feature is unavailable."
            }
        case .previewDisabled:
            "Turn on the preview gate to use this surface. Basic Mode is unchanged."
        case .emptyData:
            "Data will appear here when there is something to show."
        case .safeModeActive:
            "Safe Mode is active. Optional Pro and Labs surfaces stay quiet until Safe Mode is cleared."
        case .serviceUnavailable:
            "This surface is available once the required local service is attached."
        case .noMatches:
            "Try a different filter or search term."
        }
    }

    var defaultSystemImage: String {
        switch self {
        case .proModeDisabled:
            "hand.raised.slash"
        case .permissionMissing:
            "lock"
        case .previewDisabled:
            "eye.slash"
        case .emptyData:
            "tray"
        case .safeModeActive:
            "lifepreserver"
        case .serviceUnavailable:
            "wrench.and.screwdriver"
        case .noMatches:
            "line.3.horizontal.decrease.circle"
        }
    }

    var style: ClearGlassStatusStyle {
        switch self {
        case .proModeDisabled, .emptyData, .serviceUnavailable, .noMatches:
            .secondary
        case .permissionMissing, .previewDisabled, .safeModeActive:
            .warning
        }
    }
}

struct SettingsUnavailableGate<Actions: View>: View {
    private let reason: SettingsUnavailableReason
    private let title: String
    private let message: String
    private let systemImage: String
    private let minHeight: CGFloat
    private let showsActions: Bool
    @ViewBuilder private let actions: Actions

    init(
        _ reason: SettingsUnavailableReason,
        title: String? = nil,
        message: String? = nil,
        systemImage: String? = nil,
        minHeight: CGFloat = 160,
        showsActions: Bool = true,
        @ViewBuilder actions: () -> Actions
    ) {
        self.reason = reason
        self.title = title ?? reason.defaultTitle
        self.message = message ?? reason.defaultMessage
        self.systemImage = systemImage ?? reason.defaultSystemImage
        self.minHeight = minHeight
        self.showsActions = showsActions
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: 13) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(reason.style.tint)
                    .frame(width: 34, height: 34)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 460)
            }
            .accessibilityElement(children: .combine)

            if showsActions {
                HStack(spacing: 8) {
                    actions
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(reason.style.background, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(reason.style.border, lineWidth: 0.5)
        }
    }
}

extension SettingsUnavailableGate where Actions == EmptyView {
    init(
        _ reason: SettingsUnavailableReason,
        title: String? = nil,
        message: String? = nil,
        systemImage: String? = nil,
        minHeight: CGFloat = 160
    ) {
        self.init(
            reason,
            title: title,
            message: message,
            systemImage: systemImage,
            minHeight: minHeight,
            showsActions: false
        ) {
            EmptyView()
        }
    }
}
