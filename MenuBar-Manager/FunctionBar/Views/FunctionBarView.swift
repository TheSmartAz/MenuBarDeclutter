import SwiftUI

struct FunctionBarView: View {
    @Bindable var viewModel: FunctionBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if viewModel.showsSetSwitcher {
                    SetSwitcherView(
                        activeWorkspace: viewModel.activeWorkspace,
                        workspaces: viewModel.availableWorkspaces,
                        onSwitch: viewModel.switchWorkspace(id:)
                    )
                }

                Text("Preview")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12), in: .capsule)

                Spacer(minLength: 12)

                if let feedback = viewModel.feedbackMessage {
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Button("Close", systemImage: "xmark", action: viewModel.hide)
                    .labelStyle(.iconOnly)
                    .help("Close Function Bar")
            }

            FunctionBarItemsStrip(
                items: viewModel.items,
                showsLabels: viewModel.showsLabels,
                density: FunctionBarDensity(rawValue: viewModel.density) ?? .regular,
                onActivate: viewModel.activate(_:),
                onProxyAction: viewModel.performProxyAction(_:for:)
            )
        }
        .padding(12)
        .frame(minWidth: 420, idealWidth: 720, maxWidth: .infinity, minHeight: 88)
        .accessibilityIdentifier("functionBar.preview")
        .onHover(perform: viewModel.hoverChanged(_:))
    }
}

private struct FunctionBarItemsStrip: View {
    let items: [FunctionBarItemModel]
    let showsLabels: Bool
    let density: FunctionBarDensity
    let onActivate: (FunctionBarItemModel) -> Void
    let onProxyAction: (FunctionBarProxyAction, FunctionBarItemModel) -> Void

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("This workspace has no function items yet.", systemImage: "menubar.rectangle")
                .frame(maxWidth: .infinity, minHeight: 42)
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        FunctionBarItemView(item: item, showsLabel: showsLabels, density: density) {
                            onActivate(item)
                        } onProxyAction: { action in
                            onProxyAction(action, item)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct FunctionBarItemView: View {
    let item: FunctionBarItemModel
    let showsLabel: Bool
    let density: FunctionBarDensity
    let onActivate: () -> Void
    let onProxyAction: (FunctionBarProxyAction) -> Void

    var body: some View {
        switch item.kind {
        case .spacer:
            FunctionBarSpacerView()
        case .divider:
            Divider()
                .frame(height: 28)
        default:
            Button(action: onActivate) {
                HStack(spacing: 6) {
                    Image(systemName: item.icon.systemName)
                        .frame(width: 18)
                    if showsLabel {
                        Text(item.title)
                            .font(.callout)
                            .lineLimit(1)
                    }
                    if showsLabel, let badge = item.badge {
                        Text(badge.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, density.horizontalPadding)
                .padding(.vertical, density.verticalPadding)
                .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                }
            }
            .buttonStyle(.plain)
            .disabled(!item.availability.isAvailable)
            .opacity(item.availability.isAvailable ? 1 : 0.58)
            .help(item.subtitle ?? item.status.displayText)
            .accessibilityLabel(item.title)
            .contextMenu {
                if case .menuBarItem = item.kind, item.availability.isAvailable {
                    ForEach(FunctionBarProxyAction.allCases) { action in
                        Button(action.title, systemImage: action.systemImage) {
                            onProxyAction(action)
                        }
                    }
                }
            }
        }
    }
}

enum FunctionBarDensity: String, CaseIterable, Identifiable, Sendable {
    case compact
    case regular

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: "Compact"
        case .regular: "Regular"
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: 8
        case .regular: 10
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: 5
        case .regular: 7
        }
    }
}

struct FunctionBarSpacerView: View {
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 22, height: 28)
            .overlay {
                Image(systemName: "arrow.left.and.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .help("Spacer")
    }
}

struct SetSwitcherView: View {
    let activeWorkspace: MenuBarWorkspace?
    let workspaces: [MenuBarWorkspace]
    let onSwitch: (UUID) -> Void

    var body: some View {
        Menu {
            ForEach(workspaces) { workspace in
                Button {
                    onSwitch(workspace.id)
                } label: {
                    Label(
                        WorkspaceDiagnosticsRedactor.displayName(for: workspace),
                        systemImage: activeWorkspace?.id == workspace.id ? "checkmark.circle" : workspace.iconName
                    )
                }
            }
        } label: {
            Label(activeWorkspace.map(WorkspaceDiagnosticsRedactor.displayName(for:)) ?? "Workspace", systemImage: "rectangle.3.group")
        }
        .menuStyle(.button)
        .help("Switch Workspace")
        .accessibilityIdentifier("functionBar.setSwitcher")
    }
}
