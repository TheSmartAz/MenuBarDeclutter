import SwiftUI

struct SecondBarCompactStripActivationFeedback: Equatable {
    enum Tone: Equatable {
        case warning
        case success
    }

    let message: String
    let tone: Tone
    let retrySnapshot: MenuBarItemSnapshot?

    init(
        message: String,
        tone: Tone,
        retrySnapshot: MenuBarItemSnapshot? = nil
    ) {
        self.message = message
        self.tone = tone
        self.retrySnapshot = retrySnapshot
    }
}

struct SecondBarCompactStripRootView: View {
    enum Content {
        case ready(plan: SecondBarCompactStripPlan)
        case requirements(ProSecondBarReadinessState)
    }

    let content: Content
    let activationFeedback: SecondBarCompactStripActivationFeedback?
    let onActivate: (MenuBarItemSnapshot) -> Void
    let onRetryActivation: (MenuBarItemSnapshot) -> Void
    let onOpenManage: () -> Void
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            switch content {
            case .ready(let plan):
                ReadyCompactStripContent(
                    plan: plan,
                    activationFeedback: activationFeedback,
                    onActivate: onActivate,
                    onRetryActivation: onRetryActivation,
                    onOpenManage: onOpenManage,
                    onOpenSettings: onOpenSettings
                )
            case .requirements(let readiness):
                RequirementsCompactStripContent(
                    readiness: readiness,
                    onOpenSettings: onOpenSettings,
                    onDismiss: onDismiss
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
        .background(.bar, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.22), lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("secondBar.compactStrip")
    }
}

private struct ReadyCompactStripContent: View {
    let plan: SecondBarCompactStripPlan
    let activationFeedback: SecondBarCompactStripActivationFeedback?
    let onActivate: (MenuBarItemSnapshot) -> Void
    let onRetryActivation: (MenuBarItemSnapshot) -> Void
    let onOpenManage: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: SecondBarCompactStripPlanner.interItemSpacing) {
            if plan.visibleItems.isEmpty {
                EmptyReadyState(plan: plan)
            } else {
                ForEach(plan.visibleItems) { snapshot in
                    CompactStripItemButton(snapshot: snapshot) {
                        onActivate(snapshot)
                    }
                }
            }

            if let activationFeedback {
                CompactStripFeedback(
                    feedback: activationFeedback,
                    onRetryActivation: onRetryActivation
                )
            }

            if plan.hasAdditionalItems {
                CompactStripOverflowButton(
                    count: plan.totalAdditionalCount,
                    onOpenManage: onOpenManage
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct RequirementsCompactStripContent: View {
    let readiness: ProSecondBarReadinessState
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullContent
            compactContent
        }
        .help("\(readiness.displayTitle). \(readiness.message)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(readiness.displayTitle). \(readiness.message)")
        .accessibilityIdentifier("secondBar.requirements")
    }

    private var fullContent: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            statusIcon

            Text(readiness.displayTitle)
                .font(DesignTokens.Typography.callout)
                .lineLimit(1)

            Spacer(minLength: DesignTokens.Spacing.small)

            CompactStripIconButton(
                title: "Open Privacy Settings",
                systemImage: "lock.shield",
                action: onOpenSettings
            )
            CompactStripIconButton(
                title: "Close",
                systemImage: "xmark",
                action: onDismiss
            )
        }
    }

    private var compactContent: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            statusIcon
            Text(compactTitle)
                .font(DesignTokens.Typography.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 2)

            CompactStripIconButton(
                title: "Open Privacy Settings",
                systemImage: "lock.shield",
                action: onOpenSettings
            )
        }
        .frame(minWidth: 130)
    }

    private var statusIcon: some View {
        Image(systemName: "shield.lefthalf.filled")
            .font(.system(size: DesignTokens.IconSize.standard, weight: .semibold))
            .foregroundStyle(.yellow)
    }

    private var compactTitle: String {
        switch readiness {
        case .ready:
            "Ready"
        case .missingEntitlement:
            "Pro"
        case .accessibilityDiscoveryDisabled, .accessibilityPermissionMissing:
            "Access"
        case .accurateIconsDisabled:
            "Icons"
        case .screenRecordingMissing:
            "Screen"
        }
    }
}

private struct CompactStripItemButton: View {
    let snapshot: MenuBarItemSnapshot
    let action: () -> Void

    var body: some View {
        let metrics = SecondBarCompactStripPlanner.itemMetrics(for: snapshot)

        Button(action: action) {
            MenuBarItemIconView(
                snapshot: snapshot,
                imageSize: metrics.imageSize,
                cornerRadius: metrics.cornerRadius
            )
        }
        .buttonStyle(.plain)
        .frame(width: metrics.slotSize.width, height: metrics.slotSize.height)
        .contentShape(.rect(cornerRadius: 5))
        .help("Activate \(displayTitle)")
        .accessibilityRepresentation {
            Button("Activate \(displayTitle)", action: action)
                .accessibilityValue(snapshot.id)
                .accessibilityIdentifier("secondBar.compact.item.\(snapshot.id)")
        }
    }

    private var displayTitle: String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }
}

private struct CompactStripOverflowButton: View {
    let count: Int
    let onOpenManage: () -> Void

    var body: some View {
        Button("+\(count)", action: onOpenManage)
            .buttonStyle(.plain)
            .font(DesignTokens.Typography.caption)
            .bold()
            .foregroundStyle(.primary)
            .frame(width: 34, height: 26)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: .rect(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.18), lineWidth: DesignTokens.Stroke.hairline)
            }
            .help("Open Second Bar Manage Panel")
            .accessibilityLabel("\(count) more Second Bar items")
            .accessibilityIdentifier("secondBar.compact.overflow")
    }
}

private struct CompactStripIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: .rect(cornerRadius: 5))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.18), lineWidth: DesignTokens.Stroke.hairline)
        }
        .help(title)
        .accessibilityLabel(title)
    }
}

private struct CompactStripScanStateBadge: View {
    let scanState: SecondBarCompactStripScanState

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(DesignTokens.Typography.caption)
            .lineLimit(1)
            .foregroundStyle(.yellow)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .frame(height: 28)
            .background(Color.yellow.opacity(0.10), in: .rect(cornerRadius: DesignTokens.Radius.control))
            .help(help)
            .accessibilityIdentifier("secondBar.compact.scanState")
    }

    private var title: String {
        switch scanState {
        case .fresh:
            "Scan ready"
        case .stale:
            "Scan stale"
        case .noScan:
            "No scan yet"
        }
    }

    private var systemImage: String {
        switch scanState {
        case .fresh:
            "checkmark.circle"
        case .stale:
            "clock.badge.exclamationmark"
        case .noScan:
            "arrow.triangle.2.circlepath"
        }
    }

    private var help: String {
        switch scanState {
        case .fresh:
            "Menu bar scan is current."
        case .stale:
            "Menu bar scan may be stale. Refresh from the Manage panel."
        case .noScan:
            "No menu bar scan is available yet. Refresh from the Manage panel."
        }
    }
}

private struct CompactStripFeedback: View {
    let feedback: SecondBarCompactStripActivationFeedback
    let onRetryActivation: (MenuBarItemSnapshot) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Label(feedback.message, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            if let retrySnapshot = feedback.retrySnapshot {
                Button {
                    onRetryActivation(retrySnapshot)
                } label: {
                    Label("Retry Activation", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .font(DesignTokens.Typography.caption)
                .background(.regularMaterial, in: .rect(cornerRadius: DesignTokens.Radius.control))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                        .strokeBorder(foregroundStyle.opacity(0.28), lineWidth: DesignTokens.Stroke.hairline)
                }
                .help("Retry activating the menu bar item")
                .accessibilityLabel("Retry Activation")
                .accessibilityIdentifier("secondBar.compact.retryActivation")
            }
        }
        .font(DesignTokens.Typography.caption)
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, DesignTokens.Spacing.small)
        .frame(height: 26)
        .background(foregroundStyle.opacity(0.10), in: .rect(cornerRadius: 5))
    }

    private var systemImage: String {
        switch feedback.tone {
        case .warning:
            "exclamationmark.triangle"
        case .success:
            "checkmark.circle"
        }
    }

    private var foregroundStyle: Color {
        switch feedback.tone {
        case .warning:
            .yellow
        case .success:
            .green
        }
    }
}

private struct EmptyReadyState: View {
    let plan: SecondBarCompactStripPlan

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var message: String {
        switch plan.scanState {
        case .noScan:
            return "No scan yet"
        case .stale:
            return "Scan stale"
        case .fresh:
            break
        }

        if plan.needsAccurateIconCount > 0 {
            return "Preparing icons"
        }
        return "No hidden icons"
    }

    private var systemImage: String {
        switch plan.scanState {
        case .noScan:
            "arrow.triangle.2.circlepath"
        case .stale:
            "clock.badge.exclamationmark"
        case .fresh:
            plan.needsAccurateIconCount > 0 ? "photo.badge.exclamationmark" : "rectangle.dashed"
        }
    }
}

#Preview {
    SecondBarCompactStripRootView(
        content: .ready(plan: SecondBarCompactStripPlan(
            visibleItems: [
                MenuBarItemSnapshot(
                    id: "preview",
                    title: "Sync",
                    role: "AXMenuBarItem",
                    subrole: nil,
                    frame: .zero,
                    owningProcessIdentifier: nil,
                    owningApplicationName: "Example",
                    bundleIdentifier: "com.example.app",
                    zone: .hidden,
                    isLikelySystemItem: false,
                    scanTimestamp: Date()
                )
            ],
            hiddenOverflowCount: 2,
            needsAccurateIconCount: 1,
            scanState: .fresh
        )),
        activationFeedback: nil,
        onActivate: { _ in },
        onRetryActivation: { _ in },
        onOpenManage: {},
        onOpenSettings: {},
        onDismiss: {}
    )
    .frame(width: 520)
    .padding()
}
